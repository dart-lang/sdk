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
        #F1 hasInitializer f @6
          element: <testLibrary>::@topLevelVariable::f
          getter: #F2
      getters
        #F2 synthetic f
          element: <testLibrary>::@getter::f
          returnType: V Function<U, V>(U, V)
          variable: #F1
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
    #F0 <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      topLevelVariables
        #F2 hasInitializer f @19
          element: <testLibrary>::@topLevelVariable::f
          getter: #F3
      getters
        #F3 synthetic f
          element: <testLibrary>::@getter::f
          returnType: double Function(int)
          variable: #F2
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @8
              element: #E0 T
          fields
            #F3 hasInitializer f @21
              element: <testLibrary>::@class::C::@field::f
              getter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic f
              element: <testLibrary>::@class::C::@getter::f
              returnType: InvalidType
              variable: #F3
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
          firstFragment: #F5
      getters
        synthetic f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F4
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
        #F1 class C @43
          element: <testLibrary>::@class::C
          typeParameters
            #F2 V @45
              element: #E0 V
          constructors
            #F3 const new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 58
              formalParameters
                #F4 f @65
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::f
        #F5 class D @77
          element: <testLibrary>::@class::D
          typeParameters
            #F6 T @79
              element: #E1 T
            #F7 U @81
              element: #E2 U
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      typeAliases
        #F9 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F10 T @10
              element: #E3 T
      topLevelVariables
        #F11 hasInitializer x @118
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
          getter: #F12
      getters
        #F12 synthetic x
          element: <testLibrary>::@getter::x
          returnType: C<int>
          variable: #F11
      functions
        #F13 f @96
          element: <testLibrary>::@function::f
          typeParameters
            #F14 U @98
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
            requiredPositional f
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
        #F1 class C @38
          element: <testLibrary>::@class::C
          constructors
            #F2 const new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 50
              formalParameters
                #F3 f @54
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::f
        #F4 class D @66
          element: <testLibrary>::@class::D
          typeParameters
            #F5 T @68
              element: #E0 T
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      typeAliases
        #F7 F @8
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F8 hasInitializer x @101
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
          getter: #F9
      getters
        #F9 synthetic x
          element: <testLibrary>::@getter::x
          returnType: C
          variable: #F8
      functions
        #F10 f @79
          element: <testLibrary>::@function::f
          typeParameters
            #F11 T @81
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
            requiredPositional f
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B @18
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class S @40
          element: <testLibrary>::@class::S
          typeParameters
            #F6 T @42
              element: #E0 T
          constructors
            #F7 new
              element: <testLibrary>::@class::S::@constructor::new
              typeName: S
              typeNameOffset: 59
              formalParameters
                #F8 _ @63
                  element: <testLibrary>::@class::S::@constructor::new::@formalParameter::_
      topLevelVariables
        #F9 hasInitializer s @74
          element: <testLibrary>::@topLevelVariable::s
          getter: #F10
          setter: #F11
      getters
        #F10 synthetic s
          element: <testLibrary>::@getter::s
          returnType: S<B>
          variable: #F9
      setters
        #F11 synthetic s
          element: <testLibrary>::@setter::s
          formalParameters
            #F12 _s
              element: <testLibrary>::@setter::s::@formalParameter::_s
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
            requiredPositional _
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
        requiredPositional _s
          firstFragment: #F12
          type: S<B>
      returnType: void
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 b @14
              element: <testLibrary>::@class::A::@field::b
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic b
              element: <testLibrary>::@class::A::@getter::b
              returnType: B
              variable: #F2
          setters
            #F4 synthetic b
              element: <testLibrary>::@class::A::@setter::b
              formalParameters
                #F6 _b
                  element: <testLibrary>::@class::A::@setter::b::@formalParameter::_b
        #F7 class B @25
          element: <testLibrary>::@class::B
          fields
            #F8 synthetic c
              element: <testLibrary>::@class::B::@field::c
              getter2: #F9
              setter2: #F10
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F9 c @37
              element: <testLibrary>::@class::B::@getter::c
              returnType: C
              variable: #F8
          setters
            #F10 c @59
              element: <testLibrary>::@class::B::@setter::c
              formalParameters
                #F12 value @63
                  element: <testLibrary>::@class::B::@setter::c::@formalParameter::value
        #F13 class C @81
          element: <testLibrary>::@class::C
          constructors
            #F14 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F15 class D @92
          element: <testLibrary>::@class::D
          constructors
            #F16 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      topLevelVariables
        #F17 hasInitializer a @111
          element: <testLibrary>::@topLevelVariable::a
          getter: #F18
          setter: #F19
        #F20 hasInitializer x @128
          element: <testLibrary>::@topLevelVariable::x
          getter: #F21
          setter: #F22
      getters
        #F18 synthetic a
          element: <testLibrary>::@getter::a
          returnType: A
          variable: #F17
        #F21 synthetic x
          element: <testLibrary>::@getter::x
          returnType: C
          variable: #F20
      setters
        #F19 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F23 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F22 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F24 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  classes
    class A
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
          firstFragment: #F5
      getters
        synthetic b
          reference: <testLibrary>::@class::A::@getter::b
          firstFragment: #F3
          returnType: B
          variable: <testLibrary>::@class::A::@field::b
      setters
        synthetic b
          reference: <testLibrary>::@class::A::@setter::b
          firstFragment: #F4
          formalParameters
            requiredPositional _b
              firstFragment: #F6
              type: B
          returnType: void
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
          firstFragment: #F11
      getters
        c
          reference: <testLibrary>::@class::B::@getter::c
          firstFragment: #F9
          returnType: C
          variable: <testLibrary>::@class::B::@field::c
      setters
        c
          reference: <testLibrary>::@class::B::@setter::c
          firstFragment: #F10
          formalParameters
            requiredPositional value
              firstFragment: #F12
              type: C
          returnType: void
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
      firstFragment: #F20
      type: C
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F18
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F21
      returnType: C
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F19
      formalParameters
        requiredPositional _a
          firstFragment: #F23
          type: A
      returnType: void
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F22
      formalParameters
        requiredPositional _x
          firstFragment: #F24
          type: C
      returnType: void
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
        #F1 hasInitializer x @4
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
        #F4 hasInitializer y @40
          element: <testLibrary>::@topLevelVariable::y
          getter: #F5
          setter: #F6
        #F7 hasInitializer z @53
          element: <testLibrary>::@topLevelVariable::z
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: Iterable<String>
          variable: #F1
        #F5 synthetic y
          element: <testLibrary>::@getter::y
          returnType: List<int>
          variable: #F4
        #F8 synthetic z
          element: <testLibrary>::@getter::z
          returnType: List<String>
          variable: #F7
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F10 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
        #F6 synthetic y
          element: <testLibrary>::@setter::y
          formalParameters
            #F11 _y
              element: <testLibrary>::@setter::y::@formalParameter::_y
        #F9 synthetic z
          element: <testLibrary>::@setter::z
          formalParameters
            #F12 _z
              element: <testLibrary>::@setter::z::@formalParameter::_z
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Iterable<String>
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
    hasInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F4
      type: List<int>
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
    hasInitializer z
      reference: <testLibrary>::@topLevelVariable::z
      firstFragment: #F7
      type: List<String>
      getter: <testLibrary>::@getter::z
      setter: <testLibrary>::@setter::z
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Iterable<String>
      variable: <testLibrary>::@topLevelVariable::x
    synthetic static y
      reference: <testLibrary>::@getter::y
      firstFragment: #F5
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::y
    synthetic static z
      reference: <testLibrary>::@getter::z
      firstFragment: #F8
      returnType: List<String>
      variable: <testLibrary>::@topLevelVariable::z
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        requiredPositional _x
          firstFragment: #F10
          type: Iterable<String>
      returnType: void
    synthetic static y
      reference: <testLibrary>::@setter::y
      firstFragment: #F6
      formalParameters
        requiredPositional _y
          firstFragment: #F11
          type: List<int>
      returnType: void
    synthetic static z
      reference: <testLibrary>::@setter::z
      firstFragment: #F9
      formalParameters
        requiredPositional _z
          firstFragment: #F12
          type: List<String>
      returnType: void
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          fields
            #F2 p @16
              element: <testLibrary>::@class::C::@field::p
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 synthetic p
              element: <testLibrary>::@class::C::@getter::p
              returnType: int
              variable: #F2
          setters
            #F4 synthetic p
              element: <testLibrary>::@class::C::@setter::p
              formalParameters
                #F6 _p
                  element: <testLibrary>::@class::C::@setter::p::@formalParameter::_p
      topLevelVariables
        #F7 hasInitializer x @25
          element: <testLibrary>::@topLevelVariable::x
          getter: #F8
          setter: #F9
        #F10 hasInitializer y @40
          element: <testLibrary>::@topLevelVariable::y
          getter: #F11
          setter: #F12
      getters
        #F8 synthetic x
          element: <testLibrary>::@getter::x
          returnType: List<C>
          variable: #F7
        #F11 synthetic y
          element: <testLibrary>::@getter::y
          returnType: Iterable<int>
          variable: #F10
      setters
        #F9 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F13 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
        #F12 synthetic y
          element: <testLibrary>::@setter::y
          formalParameters
            #F14 _y
              element: <testLibrary>::@setter::y::@formalParameter::_y
  classes
    class C
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
          firstFragment: #F5
      getters
        synthetic p
          reference: <testLibrary>::@class::C::@getter::p
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::C::@field::p
      setters
        synthetic p
          reference: <testLibrary>::@class::C::@setter::p
          firstFragment: #F4
          formalParameters
            requiredPositional _p
              firstFragment: #F6
              type: int
          returnType: void
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: List<C>
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
    hasInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F10
      type: Iterable<int>
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F8
      returnType: List<C>
      variable: <testLibrary>::@topLevelVariable::x
    synthetic static y
      reference: <testLibrary>::@getter::y
      firstFragment: #F11
      returnType: Iterable<int>
      variable: <testLibrary>::@topLevelVariable::y
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F9
      formalParameters
        requiredPositional _x
          firstFragment: #F13
          type: List<C>
      returnType: void
    synthetic static y
      reference: <testLibrary>::@setter::y
      firstFragment: #F12
      formalParameters
        requiredPositional _y
          firstFragment: #F14
          type: Iterable<int>
      returnType: void
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
        #F1 f @0
          element: <testLibrary>::@function::f
          typeParameters
            #F2 U @2
              element: #E0 U
            #F3 V @5
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 U @8
              element: #E0 U
            #F3 V @11
              element: #E1 V
          fields
            #F4 x @24
              element: <testLibrary>::@class::C::@field::x
              getter2: #F5
          constructors
            #F6 new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
          getters
            #F5 synthetic x
              element: <testLibrary>::@class::C::@getter::x
              returnType: dynamic
              variable: #F4
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
          firstFragment: #F6
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 U @8
              element: #E0 U
            #F3 V @11
              element: #E1 V
          fields
            #F4 synthetic x
              element: <testLibrary>::@class::C::@field::x
              getter2: #F5
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 x @22
              element: <testLibrary>::@class::C::@getter::x
              returnType: dynamic
              variable: #F4
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
          firstFragment: #F6
      getters
        x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F4 f @15
              element: <testLibrary>::@class::C::@method::f
              typeParameters
                #F5 U @17
                  element: #E1 U
                #F6 V @20
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 U @8
              element: #E0 U
            #F3 V @11
              element: #E1 V
          fields
            #F4 synthetic x
              element: <testLibrary>::@class::C::@field::x
              setter2: #F5
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F5 x @27
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value @29
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
          firstFragment: #F6
      setters
        x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F5
          formalParameters
            requiredPositional hasImplicitType value
              firstFragment: #F7
              type: dynamic
          returnType: void
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
        #F1 f @0
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T @2
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
        #F1 f @0
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T @2
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 P @8
              element: #E0 P
          constructors
            #F3 factory new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 35
              formalParameters
                #F4 p @49
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::p
            #F5 _ @66
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 64
              periodOffset: 65
      topLevelVariables
        #F6 hasInitializer c @78
          element: <testLibrary>::@topLevelVariable::c
          getter: #F7
          setter: #F8
      getters
        #F7 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C<num>
          variable: #F6
      setters
        #F8 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F9 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
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
            requiredPositional p
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
        requiredPositional _c
          firstFragment: #F9
          type: C<num>
      returnType: void
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer foo @25
              element: <testLibrary>::@class::A::@field::foo
              getter2: #F3
            #F4 hasInitializer bar @56
              element: <testLibrary>::@class::A::@field::bar
              getter2: #F5
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic foo
              element: <testLibrary>::@class::A::@getter::foo
              returnType: int
              variable: #F2
            #F5 synthetic bar
              element: <testLibrary>::@class::A::@getter::bar
              returnType: int Function(double)
              variable: #F4
          methods
            #F7 baz @100
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
          firstFragment: #F4
          type: int Function(double)
          getter: <testLibrary>::@class::A::@getter::bar
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        synthetic static foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
        synthetic static bar
          reference: <testLibrary>::@class::A::@getter::bar
          firstFragment: #F5
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
        #F1 hasInitializer x @21
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
      functions
        #F5 m @4
          element: <testLibrary>::@function::m
          typeParameters
            #F6 T @6
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
        requiredPositional _x
          firstFragment: #F4
          type: int
      returnType: void
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
        #F1 hasInitializer m @19
          element: <testLibrary>::@topLevelVariable::m
          getter: #F2
          setter: #F3
        #F4 hasInitializer n @53
          element: <testLibrary>::@topLevelVariable::n
          getter: #F5
          setter: #F6
        #F7 hasInitializer x @73
          element: <testLibrary>::@topLevelVariable::x
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic m
          element: <testLibrary>::@getter::m
          returnType: int Function<T>()?
          variable: #F1
        #F5 synthetic n
          element: <testLibrary>::@getter::n
          returnType: int Function<T>()
          variable: #F4
        #F8 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F7
      setters
        #F3 synthetic m
          element: <testLibrary>::@setter::m
          formalParameters
            #F10 _m
              element: <testLibrary>::@setter::m::@formalParameter::_m
        #F6 synthetic n
          element: <testLibrary>::@setter::n
          formalParameters
            #F11 _n
              element: <testLibrary>::@setter::n::@formalParameter::_n
        #F9 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F12 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  topLevelVariables
    hasInitializer m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: #F1
      type: int Function<T>()?
      getter: <testLibrary>::@getter::m
      setter: <testLibrary>::@setter::m
    hasInitializer n
      reference: <testLibrary>::@topLevelVariable::n
      firstFragment: #F4
      type: int Function<T>()
      getter: <testLibrary>::@getter::n
      setter: <testLibrary>::@setter::n
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static m
      reference: <testLibrary>::@getter::m
      firstFragment: #F2
      returnType: int Function<T>()?
      variable: <testLibrary>::@topLevelVariable::m
    synthetic static n
      reference: <testLibrary>::@getter::n
      firstFragment: #F5
      returnType: int Function<T>()
      variable: <testLibrary>::@topLevelVariable::n
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static m
      reference: <testLibrary>::@setter::m
      firstFragment: #F3
      formalParameters
        requiredPositional _m
          firstFragment: #F10
          type: int Function<T>()?
      returnType: void
    synthetic static n
      reference: <testLibrary>::@setter::n
      firstFragment: #F6
      formalParameters
        requiredPositional _n
          firstFragment: #F11
          type: int Function<T>()
      returnType: void
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F9
      formalParameters
        requiredPositional _x
          firstFragment: #F12
          type: int
      returnType: void
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
        #F1 hasInitializer m @30
          element: <testLibrary>::@topLevelVariable::m
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic m
          element: <testLibrary>::@getter::m
          returnType: HashMap<dynamic, dynamic>
          variable: #F1
      setters
        #F3 synthetic m
          element: <testLibrary>::@setter::m
          formalParameters
            #F4 _m
              element: <testLibrary>::@setter::m::@formalParameter::_m
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
        requiredPositional _m
          firstFragment: #F4
          type: HashMap<dynamic, dynamic>
      returnType: void
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
        #F1 hasInitializer a @4
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
        #F4 hasInitializer b @19
          element: <testLibrary>::@topLevelVariable::b
          getter: #F5
          setter: #F6
        #F7 hasInitializer c @34
          element: <testLibrary>::@topLevelVariable::c
          getter: #F8
          setter: #F9
        #F10 hasInitializer d @49
          element: <testLibrary>::@topLevelVariable::d
          getter: #F11
          setter: #F12
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
          variable: #F1
        #F5 synthetic b
          element: <testLibrary>::@getter::b
          returnType: dynamic
          variable: #F4
        #F8 synthetic c
          element: <testLibrary>::@getter::c
          returnType: dynamic
          variable: #F7
        #F11 synthetic d
          element: <testLibrary>::@getter::d
          returnType: int
          variable: #F10
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F13 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F6 synthetic b
          element: <testLibrary>::@setter::b
          formalParameters
            #F14 _b
              element: <testLibrary>::@setter::b::@formalParameter::_b
        #F9 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F15 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F12 synthetic d
          element: <testLibrary>::@setter::d
          formalParameters
            #F16 _d
              element: <testLibrary>::@setter::d::@formalParameter::_d
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: dynamic
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
    hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F7
      type: dynamic
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasInitializer d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::d
      setter: <testLibrary>::@setter::d
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static d
      reference: <testLibrary>::@getter::d
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::d
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F13
          type: dynamic
      returnType: void
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F6
      formalParameters
        requiredPositional _b
          firstFragment: #F14
          type: dynamic
      returnType: void
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F9
      formalParameters
        requiredPositional _c
          firstFragment: #F15
          type: dynamic
      returnType: void
    synthetic static d
      reference: <testLibrary>::@setter::d
      firstFragment: #F12
      formalParameters
        requiredPositional _d
          firstFragment: #F16
          type: int
      returnType: void
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
        #F1 class C @31
          element: <testLibrary>::@class::C
          fields
            #F2 v @49
              element: <testLibrary>::@class::C::@field::v
              getter2: #F3
              setter2: #F4
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 synthetic v
              element: <testLibrary>::@class::C::@getter::v
              returnType: int Function(String)
                alias: <testLibrary>::@typeAlias::F
              variable: #F2
          setters
            #F4 synthetic v
              element: <testLibrary>::@class::C::@setter::v
              formalParameters
                #F6 _v
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::_v
        #F7 class D @69
          element: <testLibrary>::@class::D
          fields
            #F8 synthetic v
              element: <testLibrary>::@class::D::@field::v
              getter2: #F9
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F9 v @79
              element: <testLibrary>::@class::D::@getter::v
              returnType: int Function(String)
                alias: <testLibrary>::@typeAlias::F
              variable: #F8
      typeAliases
        #F11 F @12
          element: <testLibrary>::@typeAlias::F
  classes
    class C
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
          firstFragment: #F5
          superConstructor: <testLibrary>::@class::D::@constructor::new
      getters
        synthetic v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F3
          returnType: int Function(String)
            alias: <testLibrary>::@typeAlias::F
          variable: <testLibrary>::@class::C::@field::v
      setters
        synthetic v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F4
          formalParameters
            requiredPositional _v
              firstFragment: #F6
              type: int Function(String)
                alias: <testLibrary>::@typeAlias::F
          returnType: void
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
          firstFragment: #F10
      getters
        abstract v
          reference: <testLibrary>::@class::D::@getter::v
          firstFragment: #F9
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
        #F1 hasInitializer x @21
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
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
        requiredPositional _x
          firstFragment: #F4
          type: int
      returnType: void
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
        #F1 hasInitializer x @21
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int?
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
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
        requiredPositional _x
          firstFragment: #F4
          type: int?
      returnType: void
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
        #F1 hasInitializer x @21
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: void Function()
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
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
        requiredPositional _x
          firstFragment: #F4
          type: void Function()
      returnType: void
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
        #F1 hasInitializer x @21
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: void Function()?
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
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
        requiredPositional _x
          firstFragment: #F4
          type: void Function()?
      returnType: void
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @8
              element: #E0 T
          fields
            #F3 v @37
              element: <testLibrary>::@class::C::@field::v
              getter2: #F4
              setter2: #F5
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic v
              element: <testLibrary>::@class::C::@getter::v
              returnType: Map<T, int>
              variable: #F3
          setters
            #F5 synthetic v
              element: <testLibrary>::@class::C::@setter::v
              formalParameters
                #F7 _v
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::_v
        #F8 class D @57
          element: <testLibrary>::@class::D
          typeParameters
            #F9 U @59
              element: #E1 U
            #F10 V @62
              element: #E2 V
          fields
            #F11 synthetic v
              element: <testLibrary>::@class::D::@field::v
              getter2: #F12
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F12 v @83
              element: <testLibrary>::@class::D::@getter::v
              returnType: Map<V, U>
              variable: #F11
  classes
    class C
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
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::D::@constructor::new
      getters
        synthetic v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: Map<T, int>
          variable: <testLibrary>::@class::C::@field::v
      setters
        synthetic v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _v
              firstFragment: #F7
              type: Map<T, int>
          returnType: void
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
          firstFragment: #F13
      getters
        abstract v
          reference: <testLibrary>::@class::D::@getter::v
          firstFragment: #F12
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
        #F1 F @13
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F2 hasInitializer v @53
          element: <testLibrary>::@topLevelVariable::v
          getter: #F3
          setter: #F4
      getters
        #F3 synthetic v
          element: <testLibrary>::@getter::v
          returnType: dynamic
          variable: #F2
      setters
        #F4 synthetic v
          element: <testLibrary>::@setter::v
          formalParameters
            #F5 _v
              element: <testLibrary>::@setter::v::@formalParameter::_v
      functions
        #F6 h @33
          element: <testLibrary>::@function::h
          formalParameters
            #F7 f @37
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
        requiredPositional _v
          firstFragment: #F5
          type: dynamic
      returnType: void
  functions
    h
      reference: <testLibrary>::@function::h
      firstFragment: #F6
      formalParameters
        requiredPositional f
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @8
              element: #E0 T
            #F3 U @11
              element: #E1 U
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F5 f @41
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F6 x @47
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::x
                #F7 g @50
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::g
        #F8 class D @73
          element: <testLibrary>::@class::D
          typeParameters
            #F9 V @75
              element: #E2 V
            #F10 W @78
              element: #E3 W
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          methods
            #F12 f @90
              element: <testLibrary>::@class::D::@method::f
              formalParameters
                #F13 x @96
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::x
                #F14 g @101
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::g
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
          superConstructor: <testLibrary>::@class::D::@constructor::new
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional x
              firstFragment: #F6
              type: int
            requiredPositional hasImplicitType g
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
            requiredPositional x
              firstFragment: #F13
              type: int
            requiredPositional g
              firstFragment: #F14
              type: W Function(V)
              formalParameters
                requiredPositional s
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
        #F1 class C @23
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f @44
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F4 x @50
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::x
                #F5 g @53
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
            requiredPositional x
              firstFragment: #F4
              type: int
            requiredPositional hasImplicitType g
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f @25
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F4 x @31
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::x
                #F5 g @34
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::g
        #F6 class D @57
          element: <testLibrary>::@class::D
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          methods
            #F8 f @66
              element: <testLibrary>::@class::D::@method::f
              formalParameters
                #F9 x @72
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::x
                #F10 g @79
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::g
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
            requiredPositional x
              firstFragment: #F4
              type: int
            requiredPositional hasImplicitType g
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
            requiredPositional x
              firstFragment: #F9
              type: int
            requiredPositional g
              firstFragment: #F10
              type: int Function(String)
              formalParameters
                requiredPositional s
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
        #F1 hasInitializer v @40
          element: <testLibrary>::@topLevelVariable::v
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic v
          element: <testLibrary>::@getter::v
          returnType: dynamic
          variable: #F1
      setters
        #F3 synthetic v
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 _v
              element: <testLibrary>::@setter::v::@formalParameter::_v
      functions
        #F5 f @0
          element: <testLibrary>::@function::f
          formalParameters
            #F6 g @7
              element: <testLibrary>::@function::f::@formalParameter::g
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
        requiredPositional _v
          firstFragment: #F4
          type: dynamic
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F5
      formalParameters
        requiredPositional g
          firstFragment: #F6
          type: void Function(int, void Function())
          formalParameters
            requiredPositional x
              firstFragment: #F7
              type: int
            requiredPositional h
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
        #F1 hasInitializer v @42
          element: <testLibrary>::@topLevelVariable::v
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic v
          element: <testLibrary>::@getter::v
          returnType: dynamic
          variable: #F1
      setters
        #F3 synthetic v
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 _v
              element: <testLibrary>::@setter::v::@formalParameter::_v
      functions
        #F5 f @0
          element: <testLibrary>::@function::f
          formalParameters
            #F6 default g @8
              element: <testLibrary>::@function::f::@formalParameter::g
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
        requiredPositional _v
          firstFragment: #F4
          type: dynamic
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F5
      formalParameters
        optionalNamed g
          firstFragment: #F6
          type: void Function(int, void Function())
          formalParameters
            requiredPositional x
              firstFragment: #F7
              type: int
            requiredPositional h
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          fields
            #F2 synthetic f
              element: <testLibrary>::@class::C::@field::f
              setter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F3 f @29
              element: <testLibrary>::@class::C::@setter::f
              formalParameters
                #F5 g @31
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::g
        #F6 class D @54
          element: <testLibrary>::@class::D
          fields
            #F7 synthetic f
              element: <testLibrary>::@class::D::@field::f
              setter2: #F8
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          setters
            #F8 f @67
              element: <testLibrary>::@class::D::@setter::f
              formalParameters
                #F10 g @73
                  element: <testLibrary>::@class::D::@setter::f::@formalParameter::g
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
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::D::@constructor::new
      setters
        f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F3
          formalParameters
            requiredPositional hasImplicitType g
              firstFragment: #F5
              type: int Function(String)
          returnType: void
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
          firstFragment: #F9
      setters
        abstract f
          reference: <testLibrary>::@class::D::@setter::f
          firstFragment: #F8
          formalParameters
            requiredPositional g
              firstFragment: #F10
              type: int Function(String)
              formalParameters
                requiredPositional s
                  firstFragment: #F11
                  type: String
          returnType: void
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
        #F1 class B @23
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F3 m @39
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F4 p @41
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
            requiredPositional hasImplicitType p
              firstFragment: #F4
              type: Stream<dynamic>
          returnType: dynamic
''');
    var b = library.classes[0];
    var p = b.methods[0].formalParameters[0];
    // This test should verify that we correctly record inferred types,
    // when the type is defined in a part of an SDK library. So, test that
    // the type is actually in a part.
    var streamElement = (p.type as InterfaceType).element3;
    expect(
      streamElement.firstFragment.libraryFragment.source,
      isNot(streamElement.library2.firstFragment.source),
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
            #F3 named @21
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 19
              periodOffset: 20
      topLevelVariables
        #F4 hasInitializer a1 @36
          element: <testLibrary>::@topLevelVariable::a1
          getter: #F5
          setter: #F6
        #F7 hasInitializer a2 @50
          element: <testLibrary>::@topLevelVariable::a2
          getter: #F8
          setter: #F9
      getters
        #F5 synthetic a1
          element: <testLibrary>::@getter::a1
          returnType: A
          variable: #F4
        #F8 synthetic a2
          element: <testLibrary>::@getter::a2
          returnType: A
          variable: #F7
      setters
        #F6 synthetic a1
          element: <testLibrary>::@setter::a1
          formalParameters
            #F10 _a1
              element: <testLibrary>::@setter::a1::@formalParameter::_a1
        #F9 synthetic a2
          element: <testLibrary>::@setter::a2
          formalParameters
            #F11 _a2
              element: <testLibrary>::@setter::a2::@formalParameter::_a2
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
      firstFragment: #F7
      type: A
      getter: <testLibrary>::@getter::a2
      setter: <testLibrary>::@setter::a2
  getters
    synthetic static a1
      reference: <testLibrary>::@getter::a1
      firstFragment: #F5
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a1
    synthetic static a2
      reference: <testLibrary>::@getter::a2
      firstFragment: #F8
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a2
  setters
    synthetic static a1
      reference: <testLibrary>::@setter::a1
      firstFragment: #F6
      formalParameters
        requiredPositional _a1
          firstFragment: #F10
          type: A
      returnType: void
    synthetic static a2
      reference: <testLibrary>::@setter::a2
      firstFragment: #F9
      formalParameters
        requiredPositional _a2
          firstFragment: #F11
          type: A
      returnType: void
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
        package:test/foo.dart as foo @21
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      topLevelVariables
        #F1 hasInitializer a1 @30
          element: <testLibrary>::@topLevelVariable::a1
          getter: #F2
          setter: #F3
        #F4 hasInitializer a2 @48
          element: <testLibrary>::@topLevelVariable::a2
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic a1
          element: <testLibrary>::@getter::a1
          returnType: A
          variable: #F1
        #F5 synthetic a2
          element: <testLibrary>::@getter::a2
          returnType: A
          variable: #F4
      setters
        #F3 synthetic a1
          element: <testLibrary>::@setter::a1
          formalParameters
            #F7 _a1
              element: <testLibrary>::@setter::a1::@formalParameter::_a1
        #F6 synthetic a2
          element: <testLibrary>::@setter::a2
          formalParameters
            #F8 _a2
              element: <testLibrary>::@setter::a2::@formalParameter::_a2
  topLevelVariables
    hasInitializer a1
      reference: <testLibrary>::@topLevelVariable::a1
      firstFragment: #F1
      type: A
      getter: <testLibrary>::@getter::a1
      setter: <testLibrary>::@setter::a1
    hasInitializer a2
      reference: <testLibrary>::@topLevelVariable::a2
      firstFragment: #F4
      type: A
      getter: <testLibrary>::@getter::a2
      setter: <testLibrary>::@setter::a2
  getters
    synthetic static a1
      reference: <testLibrary>::@getter::a1
      firstFragment: #F2
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a1
    synthetic static a2
      reference: <testLibrary>::@getter::a2
      firstFragment: #F5
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a2
  setters
    synthetic static a1
      reference: <testLibrary>::@setter::a1
      firstFragment: #F3
      formalParameters
        requiredPositional _a1
          firstFragment: #F7
          type: A
      returnType: void
    synthetic static a2
      reference: <testLibrary>::@setter::a2
      firstFragment: #F6
      formalParameters
        requiredPositional _a2
          firstFragment: #F8
          type: A
      returnType: void
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
        #F1 hasInitializer v @71
          element: <testLibrary>::@topLevelVariable::v
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic v
          element: <testLibrary>::@getter::v
          returnType: List<Object Function(int Function(String))>
          variable: #F1
      setters
        #F3 synthetic v
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 _v
              element: <testLibrary>::@setter::v::@formalParameter::_v
      functions
        #F5 f @4
          element: <testLibrary>::@function::f
          formalParameters
            #F6 x @10
              element: <testLibrary>::@function::f::@formalParameter::x
        #F7 g @39
          element: <testLibrary>::@function::g
          formalParameters
            #F8 x @45
              element: <testLibrary>::@function::g::@formalParameter::x
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
        requiredPositional _v
          firstFragment: #F4
          type: List<Object Function(int Function(String))>
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F5
      formalParameters
        requiredPositional x
          firstFragment: #F6
          type: int Function(String)
          formalParameters
            requiredPositional y
              firstFragment: #F9
              type: String
      returnType: int
    g
      reference: <testLibrary>::@function::g
      firstFragment: #F7
      formalParameters
        requiredPositional x
          firstFragment: #F8
          type: int Function(String)
          formalParameters
            requiredPositional y
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
        #F1 class A @15
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @25
              element: <testLibrary>::@class::A::@method::m
        #F4 class B @48
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F6 m @61
              element: <testLibrary>::@class::B::@method::m
        #F7 class C @84
          element: <testLibrary>::@class::C
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F9 class D @121
          element: <testLibrary>::@class::D
          fields
            #F10 f @141
              element: <testLibrary>::@class::D::@field::f
              getter2: #F11
              setter2: #F12
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F11 synthetic f
              element: <testLibrary>::@class::D::@getter::f
              returnType: dynamic
              variable: #F10
          setters
            #F12 synthetic f
              element: <testLibrary>::@class::D::@setter::f
              formalParameters
                #F14 _f
                  element: <testLibrary>::@class::D::@setter::f::@formalParameter::_f
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
    abstract class D
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
          firstFragment: #F13
          superConstructor: <testLibrary>::@class::C::@constructor::new
      getters
        synthetic f
          reference: <testLibrary>::@class::D::@getter::f
          firstFragment: #F11
          returnType: dynamic
          variable: <testLibrary>::@class::D::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::D::@setter::f
          firstFragment: #F12
          formalParameters
            requiredPositional _f
              firstFragment: #F14
              type: dynamic
          returnType: void
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 call @19
              element: <testLibrary>::@class::A::@method::call
        #F4 class B @42
          element: <testLibrary>::@class::B
          fields
            #F5 a @50
              element: <testLibrary>::@class::B::@field::a
              getter2: #F6
              setter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F6 synthetic a
              element: <testLibrary>::@class::B::@getter::a
              returnType: A
              variable: #F5
          setters
            #F7 synthetic a
              element: <testLibrary>::@class::B::@setter::a
              formalParameters
                #F9 _a
                  element: <testLibrary>::@class::B::@setter::a::@formalParameter::_a
      topLevelVariables
        #F10 hasInitializer c @59
          element: <testLibrary>::@topLevelVariable::c
          getter: #F11
          setter: #F12
      getters
        #F11 synthetic c
          element: <testLibrary>::@getter::c
          returnType: double
          variable: #F10
      setters
        #F12 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F13 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
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
    class B
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
          firstFragment: #F8
      getters
        synthetic a
          reference: <testLibrary>::@class::B::@getter::a
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@class::B::@field::a
      setters
        synthetic a
          reference: <testLibrary>::@class::B::@setter::a
          firstFragment: #F7
          formalParameters
            requiredPositional _a
              firstFragment: #F9
              type: A
          returnType: void
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
        requiredPositional _c
          firstFragment: #F13
          type: double
      returnType: void
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
        #F1 hasInitializer a @4
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
        #F4 hasInitializer b @42
          element: <testLibrary>::@topLevelVariable::b
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: int Function()
          variable: #F1
        #F5 synthetic b
          element: <testLibrary>::@getter::b
          returnType: int
          variable: #F4
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F7 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F6 synthetic b
          element: <testLibrary>::@setter::b
          formalParameters
            #F8 _b
              element: <testLibrary>::@setter::b::@formalParameter::_b
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int Function()
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int Function()
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F7
          type: int Function()
      returnType: void
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F6
      formalParameters
        requiredPositional _b
          firstFragment: #F8
          type: int
      returnType: void
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
        package:test/a.dart deferred as a @28
      prefixes
        <testLibraryFragment>::@prefix2::a
          fragments: @28
      topLevelVariables
        #F1 hasInitializer x @35
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: Future<dynamic> Function()
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
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
        requiredPositional _x
          firstFragment: #F4
          type: Future<dynamic> Function()
      returnType: void
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
        #F1 hasInitializer x @4
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int Function(int Function(String))
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
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
        requiredPositional _x
          firstFragment: #F4
          type: int Function(int Function(String))
      returnType: void
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
        #F1 hasInitializer x @4
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int Function(int Function(String))
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
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
        requiredPositional _x
          firstFragment: #F4
          type: int Function(int Function(String))
      returnType: void
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
        #F1 hasInitializer y @21
          element: <testLibrary>::@topLevelVariable::y
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic y
          element: <testLibrary>::@getter::y
          returnType: int
          variable: #F1
      setters
        #F3 synthetic y
          element: <testLibrary>::@setter::y
          formalParameters
            #F4 _y
              element: <testLibrary>::@setter::y::@formalParameter::_y
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
        requiredPositional _y
          firstFragment: #F4
          type: int
      returnType: void
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer x @25
              element: <testLibrary>::@class::A::@field::x
              getter2: #F3
            #F4 hasInitializer y @51
              element: <testLibrary>::@class::A::@field::y
              getter2: #F5
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic x
              element: <testLibrary>::@class::A::@getter::x
              returnType: dynamic
              variable: #F2
            #F5 synthetic y
              element: <testLibrary>::@class::A::@getter::y
              returnType: dynamic
              variable: #F4
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
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        synthetic static x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::x
        synthetic static y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F5
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer a @25
              element: <testLibrary>::@class::A::@field::a
              getter2: #F3
            #F4 hasInitializer b @49
              element: <testLibrary>::@class::A::@field::b
              getter2: #F5
            #F6 hasInitializer c @66
              element: <testLibrary>::@class::A::@field::c
              getter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 synthetic a
              element: <testLibrary>::@class::A::@getter::a
              returnType: dynamic
              variable: #F2
            #F5 synthetic b
              element: <testLibrary>::@class::A::@getter::b
              returnType: A
              variable: #F4
            #F7 synthetic c
              element: <testLibrary>::@class::A::@getter::c
              returnType: dynamic
              variable: #F6
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
          firstFragment: #F4
          type: A
          getter: <testLibrary>::@class::A::@getter::b
        final hasInitializer c
          reference: <testLibrary>::@class::A::@field::c
          firstFragment: #F6
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::c
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F8
      getters
        synthetic static a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::a
        synthetic static b
          reference: <testLibrary>::@class::A::@getter::b
          firstFragment: #F5
          returnType: A
          variable: <testLibrary>::@class::A::@field::b
        synthetic c
          reference: <testLibrary>::@class::A::@getter::c
          firstFragment: #F7
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @8
              element: #E0 T
          fields
            #F3 value @17
              element: <testLibrary>::@class::A::@field::value
              getter2: #F4
              setter2: #F5
          constructors
            #F6 new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 27
              formalParameters
                #F7 this.value @34
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::value
          getters
            #F4 synthetic value
              element: <testLibrary>::@class::A::@getter::value
              returnType: T
              variable: #F3
          setters
            #F5 synthetic value
              element: <testLibrary>::@class::A::@setter::value
              formalParameters
                #F8 _value
                  element: <testLibrary>::@class::A::@setter::value::@formalParameter::_value
        #F9 class B @51
          element: <testLibrary>::@class::B
          fields
            #F10 hasInitializer a @61
              element: <testLibrary>::@class::B::@field::a
              getter2: #F11
              setter2: #F12
          constructors
            #F13 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F11 synthetic a
              element: <testLibrary>::@class::B::@getter::a
              returnType: A<String>
              variable: #F10
          setters
            #F12 synthetic a
              element: <testLibrary>::@class::B::@setter::a
              formalParameters
                #F14 _a
                  element: <testLibrary>::@class::B::@setter::a::@formalParameter::_a
  classes
    class A
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
          firstFragment: #F6
          formalParameters
            requiredPositional final hasImplicitType value
              firstFragment: #F7
              type: T
      getters
        synthetic value
          reference: <testLibrary>::@class::A::@getter::value
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::A::@field::value
      setters
        synthetic value
          reference: <testLibrary>::@class::A::@setter::value
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _value
              firstFragment: #F8
              type: T
          returnType: void
    class B
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
          firstFragment: #F13
      getters
        synthetic a
          reference: <testLibrary>::@class::B::@getter::a
          firstFragment: #F11
          returnType: A<String>
          variable: <testLibrary>::@class::B::@field::a
      setters
        synthetic a
          reference: <testLibrary>::@class::B::@setter::a
          firstFragment: #F12
          formalParameters
            requiredPositional _a
              firstFragment: #F14
              type: A<String>
          returnType: void
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @8
              element: #E0 T
          fields
            #F3 value @17
              element: <testLibrary>::@class::A::@field::value
              getter2: #F4
              setter2: #F5
          constructors
            #F6 new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 27
              formalParameters
                #F7 this.value @34
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::value
          getters
            #F4 synthetic value
              element: <testLibrary>::@class::A::@getter::value
              returnType: T
              variable: #F3
          setters
            #F5 synthetic value
              element: <testLibrary>::@class::A::@setter::value
              formalParameters
                #F8 _value
                  element: <testLibrary>::@class::A::@setter::value::@formalParameter::_value
        #F9 class B @51
          element: <testLibrary>::@class::B
          typeParameters
            #F10 T @53
              element: #E1 T
          constructors
            #F11 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              formalParameters
                #F12 value (offset=-1)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::value
        #F13 class C @78
          element: <testLibrary>::@class::C
          fields
            #F14 hasInitializer a @88
              element: <testLibrary>::@class::C::@field::a
              getter2: #F15
              setter2: #F16
          constructors
            #F17 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F15 synthetic a
              element: <testLibrary>::@class::C::@getter::a
              returnType: B<int>
              variable: #F14
          setters
            #F16 synthetic a
              element: <testLibrary>::@class::C::@setter::a
              formalParameters
                #F18 _a
                  element: <testLibrary>::@class::C::@setter::a::@formalParameter::_a
      mixins
        #F19 mixin M @112
          element: <testLibrary>::@mixin::M
  classes
    class A
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
          firstFragment: #F6
          formalParameters
            requiredPositional final hasImplicitType value
              firstFragment: #F7
              type: T
      getters
        synthetic value
          reference: <testLibrary>::@class::A::@getter::value
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::A::@field::value
      setters
        synthetic value
          reference: <testLibrary>::@class::A::@setter::value
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _value
              firstFragment: #F8
              type: T
          returnType: void
    class alias B
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
            requiredPositional final value
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
          superConstructor: <testLibrary>::@class::A::@constructor::new
    class C
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
          firstFragment: #F17
      getters
        synthetic a
          reference: <testLibrary>::@class::C::@getter::a
          firstFragment: #F15
          returnType: B<int>
          variable: <testLibrary>::@class::C::@field::a
      setters
        synthetic a
          reference: <testLibrary>::@class::C::@setter::a
          firstFragment: #F16
          formalParameters
            requiredPositional _a
              firstFragment: #F18
              type: B<int>
          returnType: void
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @8
              element: #E0 T
          fields
            #F3 hasInitializer f @19
              element: <testLibrary>::@class::A::@field::f
              getter2: #F4
              setter2: #F5
          constructors
            #F6 new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 28
              formalParameters
                #F7 this.f @35
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          getters
            #F4 synthetic f
              element: <testLibrary>::@class::A::@getter::f
              returnType: int
              variable: #F3
          setters
            #F5 synthetic f
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F8 _f
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::_f
  classes
    class A
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
          firstFragment: #F6
          formalParameters
            requiredPositional final hasImplicitType f
              firstFragment: #F7
              type: int
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F5
          formalParameters
            requiredPositional _f
              firstFragment: #F8
              type: int
          returnType: void
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 _ @14
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
      topLevelVariables
        #F4 hasInitializer a @26
          element: <testLibrary>::@topLevelVariable::a
          getter: #F5
        #F6 hasInitializer b @48
          element: <testLibrary>::@topLevelVariable::b
          getter: #F7
      getters
        #F5 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
          variable: #F4
        #F7 synthetic b
          element: <testLibrary>::@getter::b
          returnType: dynamic
          variable: #F6
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            requiredPositional hasImplicitType _
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
      firstFragment: #F6
      type: dynamic
      getter: <testLibrary>::@getter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
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
        #F1 hasInitializer v @38
          element: <testLibrary>::@topLevelVariable::v
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic v
          element: <testLibrary>::@getter::v
          returnType: InvalidType
          variable: #F1
      setters
        #F3 synthetic v
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 _v
              element: <testLibrary>::@setter::v::@formalParameter::_v
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
        requiredPositional _v
          firstFragment: #F4
          type: InvalidType
      returnType: void
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
        #F1 hasInitializer x @4
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: dynamic Function(dynamic) Function(dynamic)
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
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
        requiredPositional _x
          firstFragment: #F4
          type: dynamic Function(dynamic) Function(dynamic)
      returnType: void
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
        #F1 hasInitializer x @4
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int Function(int) Function(int)
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
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
        requiredPositional _x
          firstFragment: #F4
          type: int Function(int) Function(int)
      returnType: void
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
        #F1 hasInitializer x @4
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: dynamic Function([dynamic])
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
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
        requiredPositional _x
          firstFragment: #F4
          type: dynamic Function([dynamic])
      returnType: void
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
        #F1 hasInitializer a @6
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
        #F3 hasInitializer b @19
          element: <testLibrary>::@topLevelVariable::b
          getter: #F4
        #F5 hasInitializer c @32
          element: <testLibrary>::@topLevelVariable::c
          getter: #F6
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
          variable: #F1
        #F4 synthetic b
          element: <testLibrary>::@getter::b
          returnType: dynamic
          variable: #F3
        #F6 synthetic c
          element: <testLibrary>::@getter::c
          returnType: dynamic
          variable: #F5
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::b
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: dynamic
      getter: <testLibrary>::@getter::c
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
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
        #F1 hasInitializer a @6
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
        #F3 hasInitializer b @19
          element: <testLibrary>::@topLevelVariable::b
          getter: #F4
        #F5 hasInitializer c @32
          element: <testLibrary>::@topLevelVariable::c
          getter: #F6
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
          variable: #F1
        #F4 synthetic b
          element: <testLibrary>::@getter::b
          returnType: dynamic
          variable: #F3
        #F6 synthetic c
          element: <testLibrary>::@getter::c
          returnType: dynamic
          variable: #F5
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::b
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: dynamic
      getter: <testLibrary>::@getter::c
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
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
        #F1 hasInitializer a @6
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
        #F3 hasInitializer b @23
          element: <testLibrary>::@topLevelVariable::b
          getter: #F4
        #F5 hasInitializer c @36
          element: <testLibrary>::@topLevelVariable::c
          getter: #F6
        #F7 hasInitializer d @49
          element: <testLibrary>::@topLevelVariable::d
          getter: #F8
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
          variable: #F1
        #F4 synthetic b
          element: <testLibrary>::@getter::b
          returnType: dynamic
          variable: #F3
        #F6 synthetic c
          element: <testLibrary>::@getter::c
          returnType: dynamic
          variable: #F5
        #F8 synthetic d
          element: <testLibrary>::@getter::d
          returnType: dynamic
          variable: #F7
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::b
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: dynamic
      getter: <testLibrary>::@getter::c
    final hasInitializer d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F7
      type: dynamic
      getter: <testLibrary>::@getter::d
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
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
        #F1 hasInitializer a @6
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
        #F3 hasInitializer b @19
          element: <testLibrary>::@topLevelVariable::b
          getter: #F4
        #F5 hasInitializer c @36
          element: <testLibrary>::@topLevelVariable::c
          getter: #F6
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
          variable: #F1
        #F4 synthetic b
          element: <testLibrary>::@getter::b
          returnType: dynamic
          variable: #F3
        #F6 synthetic c
          element: <testLibrary>::@getter::c
          returnType: dynamic
          variable: #F5
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::b
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: dynamic
      getter: <testLibrary>::@getter::c
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B @18
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class C @40
          element: <testLibrary>::@class::C
          typeParameters
            #F6 T @42
              element: #E0 T
          fields
            #F7 f @67
              element: <testLibrary>::@class::C::@field::f
              getter2: #F8
          constructors
            #F9 const new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 78
              formalParameters
                #F10 this.f @85
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::f
          getters
            #F8 synthetic f
              element: <testLibrary>::@class::C::@getter::f
              returnType: T
              variable: #F7
      topLevelVariables
        #F11 hasInitializer b @98
          element: <testLibrary>::@topLevelVariable::b
          getter: #F12
        #F13 hasInitializer c @113
          element: <testLibrary>::@topLevelVariable::c
          getter: #F14
      getters
        #F12 synthetic b
          element: <testLibrary>::@getter::b
          returnType: B
          variable: #F11
        #F14 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C<B>
          variable: #F13
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
          firstFragment: #F9
          formalParameters
            requiredPositional final hasImplicitType f
              firstFragment: #F10
              type: T
      getters
        synthetic f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F8
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
      firstFragment: #F13
      type: C<B>
      getter: <testLibrary>::@getter::c
  getters
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F12
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
        #F1 extension <null-name> (offset=0)
          element: <testLibrary>::@extension::0
          fields
            #F2 synthetic foo
              element: <testLibrary>::@extension::0::@field::foo
              getter2: #F3
          getters
            #F3 foo @32
              element: <testLibrary>::@extension::0::@getter::foo
              returnType: int
              variable: #F2
      topLevelVariables
        #F4 hasInitializer v @48
          element: <testLibrary>::@topLevelVariable::v
          getter: #F5
          setter: #F6
      getters
        #F5 synthetic v
          element: <testLibrary>::@getter::v
          returnType: int
          variable: #F4
      setters
        #F6 synthetic v
          element: <testLibrary>::@setter::v
          formalParameters
            #F7 _v
              element: <testLibrary>::@setter::v::@formalParameter::_v
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
        requiredPositional _v
          firstFragment: #F7
          type: int
      returnType: void
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F4 F @34
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F5 hasInitializer V2 @56
          element: <testLibrary>::@topLevelVariable::V2
          getter: #F6
          setter: #F7
        #F8 hasInitializer V @71
          element: <testLibrary>::@topLevelVariable::V
          getter: #F9
          setter: #F10
      getters
        #F6 synthetic V2
          element: <testLibrary>::@getter::V2
          returnType: dynamic
          variable: #F5
        #F9 synthetic V
          element: <testLibrary>::@getter::V
          returnType: int
          variable: #F8
      setters
        #F7 synthetic V2
          element: <testLibrary>::@setter::V2
          formalParameters
            #F11 _V2
              element: <testLibrary>::@setter::V2::@formalParameter::_V2
        #F10 synthetic V
          element: <testLibrary>::@setter::V
          formalParameters
            #F12 _V
              element: <testLibrary>::@setter::V::@formalParameter::_V
      functions
        #F13 f @44
          element: <testLibrary>::@function::f
          formalParameters
            #F14 p @48
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
      firstFragment: #F8
      type: int
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    synthetic static V2
      reference: <testLibrary>::@getter::V2
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::V2
    synthetic static V
      reference: <testLibrary>::@getter::V
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::V
  setters
    synthetic static V2
      reference: <testLibrary>::@setter::V2
      firstFragment: #F7
      formalParameters
        requiredPositional _V2
          firstFragment: #F11
          type: dynamic
      returnType: void
    synthetic static V
      reference: <testLibrary>::@setter::V
      firstFragment: #F10
      formalParameters
        requiredPositional _V
          firstFragment: #F12
          type: int
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F13
      formalParameters
        requiredPositional p
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
        #F1 V @4
          element: <testLibrary>::@topLevelVariable::V
          getter: #F2
          setter: #F3
        #F4 V2 @22
          element: <testLibrary>::@topLevelVariable::V2
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic V
          element: <testLibrary>::@getter::V
          returnType: dynamic
          variable: #F1
        #F5 synthetic V2
          element: <testLibrary>::@getter::V2
          returnType: List<dynamic>
          variable: #F4
      setters
        #F3 synthetic V
          element: <testLibrary>::@setter::V
          formalParameters
            #F7 _V
              element: <testLibrary>::@setter::V::@formalParameter::_V
        #F6 synthetic V2
          element: <testLibrary>::@setter::V2
          formalParameters
            #F8 _V2
              element: <testLibrary>::@setter::V2::@formalParameter::_V2
  topLevelVariables
    V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
    V2
      reference: <testLibrary>::@topLevelVariable::V2
      firstFragment: #F4
      type: List<dynamic>
      getter: <testLibrary>::@getter::V2
      setter: <testLibrary>::@setter::V2
  getters
    synthetic static V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::V
    synthetic static V2
      reference: <testLibrary>::@getter::V2
      firstFragment: #F5
      returnType: List<dynamic>
      variable: <testLibrary>::@topLevelVariable::V2
  setters
    synthetic static V
      reference: <testLibrary>::@setter::V
      firstFragment: #F3
      formalParameters
        requiredPositional _V
          firstFragment: #F7
          type: dynamic
      returnType: void
    synthetic static V2
      reference: <testLibrary>::@setter::V2
      firstFragment: #F6
      formalParameters
        requiredPositional _V2
          firstFragment: #F8
          type: List<dynamic>
      returnType: void
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F4 m @15
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F5 p @21
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
            requiredPositional p
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
        #F1 v @4
          element: <testLibrary>::@topLevelVariable::v
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic v
          element: <testLibrary>::@getter::v
          returnType: InvalidType
          variable: #F1
      setters
        #F3 synthetic v
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 _v
              element: <testLibrary>::@setter::v::@formalParameter::_v
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
        requiredPositional _v
          firstFragment: #F4
          type: InvalidType
      returnType: void
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
        #F1 d @6
          element: <testLibrary>::@topLevelVariable::d
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic d
          element: <testLibrary>::@getter::d
          returnType: Never
          variable: #F1
      setters
        #F3 synthetic d
          element: <testLibrary>::@setter::d
          formalParameters
            #F4 _d
              element: <testLibrary>::@setter::d::@formalParameter::_d
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
        requiredPositional _d
          firstFragment: #F4
          type: Never
      returnType: void
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @8
              element: #E0 T
          fields
            #F3 t @17
              element: <testLibrary>::@class::C::@field::t
              getter2: #F4
              setter2: #F5
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic t
              element: <testLibrary>::@class::C::@getter::t
              returnType: T
              variable: #F3
          setters
            #F5 synthetic t
              element: <testLibrary>::@class::C::@setter::t
              formalParameters
                #F7 _t
                  element: <testLibrary>::@class::C::@setter::t::@formalParameter::_t
  classes
    class C
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
          firstFragment: #F6
      getters
        synthetic t
          reference: <testLibrary>::@class::C::@getter::t
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::C::@field::t
      setters
        synthetic t
          reference: <testLibrary>::@class::C::@setter::t
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _t
              firstFragment: #F7
              type: T
          returnType: void
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @8
              element: #E0 T
          fields
            #F3 t @18
              element: <testLibrary>::@class::C::@field::t
              getter2: #F4
              setter2: #F5
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic t
              element: <testLibrary>::@class::C::@getter::t
              returnType: T?
              variable: #F3
          setters
            #F5 synthetic t
              element: <testLibrary>::@class::C::@setter::t
              formalParameters
                #F7 _t
                  element: <testLibrary>::@class::C::@setter::t::@formalParameter::_t
  classes
    class C
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
          firstFragment: #F6
      getters
        synthetic t
          reference: <testLibrary>::@class::C::@getter::t
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: T?
          variable: <testLibrary>::@class::C::@field::t
      setters
        synthetic t
          reference: <testLibrary>::@class::C::@setter::t
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _t
              firstFragment: #F7
              type: T?
          returnType: void
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F3 enum E @16
          element: <testLibrary>::@enum::E
          fields
            #F4 hasInitializer v @20
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
              getter2: #F5
            #F6 synthetic values
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
              getter2: #F7
          constructors
            #F8 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
              variable: #F4
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
              variable: #F6
      typeAliases
        #F9 F @32
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F10 c @39
          element: <testLibrary>::@topLevelVariable::c
          getter: #F11
          setter: #F12
        #F13 e @44
          element: <testLibrary>::@topLevelVariable::e
          getter: #F14
          setter: #F15
        #F16 f @49
          element: <testLibrary>::@topLevelVariable::f
          getter: #F17
          setter: #F18
      getters
        #F11 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F10
        #F14 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F13
        #F17 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
          variable: #F16
      setters
        #F12 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F19 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F15 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F20 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F18 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F21 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
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
          firstFragment: #F6
          type: List<E>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
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
      firstFragment: #F13
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F16
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F11
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F14
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
      firstFragment: #F12
      formalParameters
        requiredPositional _c
          firstFragment: #F19
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F15
      formalParameters
        requiredPositional _e
          firstFragment: #F20
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F18
      formalParameters
        requiredPositional _f
          firstFragment: #F21
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
      returnType: void
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
    #F0 <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          unit: #F1
      topLevelVariables
        #F2 c @28
          element: <testLibrary>::@topLevelVariable::c
          getter: #F3
          setter: #F4
        #F5 e @33
          element: <testLibrary>::@topLevelVariable::e
          getter: #F6
          setter: #F7
        #F8 f @38
          element: <testLibrary>::@topLevelVariable::f
          getter: #F9
          setter: #F10
      getters
        #F3 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F2
        #F6 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F5
        #F9 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
          variable: #F8
      setters
        #F4 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F11 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F7 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F12 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F10 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F13 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F14 class C @17
          element: <testLibrary>::@class::C
          constructors
            #F15 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F16 enum E @27
          element: <testLibrary>::@enum::E
          fields
            #F17 hasInitializer v @31
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
              getter2: #F18
            #F19 synthetic values
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
              getter2: #F20
          constructors
            #F21 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F18 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
              variable: #F17
            #F20 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
              variable: #F19
      typeAliases
        #F22 F @43
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
          firstFragment: #F19
          type: List<E>
          constantInitializer
            fragment: #F19
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F21
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F18
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F20
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
      firstFragment: #F5
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F8
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F3
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F6
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F9
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F4
      formalParameters
        requiredPositional _c
          firstFragment: #F11
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F7
      formalParameters
        requiredPositional _e
          firstFragment: #F12
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F10
      formalParameters
        requiredPositional _f
          firstFragment: #F13
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
      returnType: void
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
    #F0 <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          unit: #F1
      classes
        #F2 class C @32
          element: <testLibrary>::@class::C
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F4 enum E @42
          element: <testLibrary>::@enum::E
          fields
            #F5 hasInitializer v @46
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
              getter2: #F6
            #F7 synthetic values
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
              getter2: #F8
          constructors
            #F9 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
              variable: #F5
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
              variable: #F7
      typeAliases
        #F10 F @58
          element: <testLibrary>::@typeAlias::F
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      topLevelVariables
        #F11 c @13
          element: <testLibrary>::@topLevelVariable::c
          getter: #F12
          setter: #F13
        #F14 e @18
          element: <testLibrary>::@topLevelVariable::e
          getter: #F15
          setter: #F16
        #F17 f @23
          element: <testLibrary>::@topLevelVariable::f
          getter: #F18
          setter: #F19
      getters
        #F12 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F11
        #F15 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F14
        #F18 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
          variable: #F17
      setters
        #F13 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F20 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F16 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F21 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F19 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F22 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
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
          firstFragment: #F7
          type: List<E>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F9
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
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
      firstFragment: #F14
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F17
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F12
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F15
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F18
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F13
      formalParameters
        requiredPositional _c
          firstFragment: #F20
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F16
      formalParameters
        requiredPositional _e
          firstFragment: #F21
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F19
      formalParameters
        requiredPositional _f
          firstFragment: #F22
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
      returnType: void
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
    #F0 <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          unit: #F1
        part_1
          uri: package:test/b.dart
          unit: #F2
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F2
      classes
        #F3 class C @17
          element: <testLibrary>::@class::C
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F5 enum E @27
          element: <testLibrary>::@enum::E
          fields
            #F6 hasInitializer v @31
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
              getter2: #F7
            #F8 synthetic values
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
              getter2: #F9
          constructors
            #F10 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
              variable: #F6
            #F9 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
              variable: #F8
      typeAliases
        #F11 F @43
          element: <testLibrary>::@typeAlias::F
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F1
      topLevelVariables
        #F12 c @13
          element: <testLibrary>::@topLevelVariable::c
          getter: #F13
          setter: #F14
        #F15 e @18
          element: <testLibrary>::@topLevelVariable::e
          getter: #F16
          setter: #F17
        #F18 f @23
          element: <testLibrary>::@topLevelVariable::f
          getter: #F19
          setter: #F20
      getters
        #F13 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F12
        #F16 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F15
        #F19 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
          variable: #F18
      setters
        #F14 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F21 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F17 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F22 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F20 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F23 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
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
          firstFragment: #F8
          type: List<E>
          constantInitializer
            fragment: #F8
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F10
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
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
      firstFragment: #F15
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F18
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
      firstFragment: #F16
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F19
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F14
      formalParameters
        requiredPositional _c
          firstFragment: #F21
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F17
      formalParameters
        requiredPositional _e
          firstFragment: #F22
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F20
      formalParameters
        requiredPositional _f
          firstFragment: #F23
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
      returnType: void
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
    #F0 <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F2 class C @17
          element: <testLibrary>::@class::C
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F4 enum E @27
          element: <testLibrary>::@enum::E
          fields
            #F5 hasInitializer v @31
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
              getter2: #F6
            #F7 synthetic values
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
              getter2: #F8
          constructors
            #F9 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
              variable: #F5
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
              variable: #F7
      typeAliases
        #F10 F @43
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F11 c @50
          element: <testLibrary>::@topLevelVariable::c
          getter: #F12
          setter: #F13
        #F14 e @55
          element: <testLibrary>::@topLevelVariable::e
          getter: #F15
          setter: #F16
        #F17 f @60
          element: <testLibrary>::@topLevelVariable::f
          getter: #F18
          setter: #F19
      getters
        #F12 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F11
        #F15 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F14
        #F18 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
          variable: #F17
      setters
        #F13 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F20 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F16 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F21 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F19 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F22 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
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
          firstFragment: #F7
          type: List<E>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F9
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
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
      firstFragment: #F14
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F17
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F12
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F15
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F18
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F13
      formalParameters
        requiredPositional _c
          firstFragment: #F20
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F16
      formalParameters
        requiredPositional _e
          firstFragment: #F21
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F19
      formalParameters
        requiredPositional _f
          firstFragment: #F22
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
      returnType: void
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F3 c @13
          element: <testLibrary>::@topLevelVariable::c
          getter: #F4
          setter: #F5
      getters
        #F4 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F3
      setters
        #F5 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F6 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
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
        requiredPositional _c
          firstFragment: #F6
          type: C
      returnType: void
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @8
              element: #E0 T
            #F3 U @11
              element: #E1 U
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F5 c @32
          element: <testLibrary>::@topLevelVariable::c
          getter: #F6
          setter: #F7
      getters
        #F6 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C<int, String>
          variable: #F5
      setters
        #F7 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
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
        requiredPositional _c
          firstFragment: #F8
          type: C<int, String>
      returnType: void
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
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @8
              element: #E0 T
            #F3 U @11
              element: #E1 U
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F5 c @19
          element: <testLibrary>::@topLevelVariable::c
          getter: #F6
          setter: #F7
      getters
        #F6 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C<dynamic, dynamic>
          variable: #F5
      setters
        #F7 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
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
        requiredPositional _c
          firstFragment: #F8
          type: C<dynamic, dynamic>
      returnType: void
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @9
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
              getter2: #F3
            #F4 synthetic values
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
              getter2: #F5
          constructors
            #F6 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
              variable: #F2
            #F5 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
              variable: #F4
      topLevelVariables
        #F7 e @15
          element: <testLibrary>::@topLevelVariable::e
          getter: #F8
          setter: #F9
      getters
        #F8 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F7
      setters
        #F9 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F10 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
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
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
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
        requiredPositional _e
          firstFragment: #F10
          type: E
      returnType: void
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
        #F1 c @19
          element: <testLibrary>::@topLevelVariable::c
          getter: #F2
          setter: #F3
        #F4 e @24
          element: <testLibrary>::@topLevelVariable::e
          getter: #F5
          setter: #F6
        #F7 f @29
          element: <testLibrary>::@topLevelVariable::f
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F1
        #F5 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F4
        #F8 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: package:test/a.dart::@typeAlias::F
          variable: #F7
      setters
        #F3 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F10 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F6 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F11 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F9 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        requiredPositional _c
          firstFragment: #F10
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        requiredPositional _e
          firstFragment: #F11
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        requiredPositional _f
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/a.dart::@typeAlias::F
      returnType: void
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
        #F1 c @19
          element: <testLibrary>::@topLevelVariable::c
          getter: #F2
          setter: #F3
        #F4 e @24
          element: <testLibrary>::@topLevelVariable::e
          getter: #F5
          setter: #F6
        #F7 f @29
          element: <testLibrary>::@topLevelVariable::f
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F1
        #F5 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F4
        #F8 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: package:test/b.dart::@typeAlias::F
          variable: #F7
      setters
        #F3 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F10 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F6 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F11 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F9 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/b.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/b.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        requiredPositional _c
          firstFragment: #F10
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        requiredPositional _e
          firstFragment: #F11
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        requiredPositional _f
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/b.dart::@typeAlias::F
      returnType: void
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
        #F1 c @19
          element: <testLibrary>::@topLevelVariable::c
          getter: #F2
          setter: #F3
        #F4 e @24
          element: <testLibrary>::@topLevelVariable::e
          getter: #F5
          setter: #F6
        #F7 f @29
          element: <testLibrary>::@topLevelVariable::f
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F1
        #F5 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F4
        #F8 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: package:test/c.dart::@typeAlias::F
          variable: #F7
      setters
        #F3 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F10 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F6 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F11 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F9 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/c.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/c.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        requiredPositional _c
          firstFragment: #F10
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        requiredPositional _e
          firstFragment: #F11
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        requiredPositional _f
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/c.dart::@typeAlias::F
      returnType: void
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
        #F1 c @21
          element: <testLibrary>::@topLevelVariable::c
          getter: #F2
          setter: #F3
        #F4 e @26
          element: <testLibrary>::@topLevelVariable::e
          getter: #F5
          setter: #F6
        #F7 f @31
          element: <testLibrary>::@topLevelVariable::f
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F1
        #F5 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F4
        #F8 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: package:test/a/c/c.dart::@typeAlias::F
          variable: #F7
      setters
        #F3 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F10 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F6 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F11 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F9 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/a/c/c.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/a/c/c.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        requiredPositional _c
          firstFragment: #F10
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        requiredPositional _e
          firstFragment: #F11
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        requiredPositional _f
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/a/c/c.dart::@typeAlias::F
      returnType: void
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
        #F1 c @21
          element: <testLibrary>::@topLevelVariable::c
          getter: #F2
          setter: #F3
        #F4 e @26
          element: <testLibrary>::@topLevelVariable::e
          getter: #F5
          setter: #F6
        #F7 f @31
          element: <testLibrary>::@topLevelVariable::f
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F1
        #F5 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F4
        #F8 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: package:test/a/b/b.dart::@typeAlias::F
          variable: #F7
      setters
        #F3 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F10 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F6 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F11 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F9 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/a/b/b.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/a/b/b.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        requiredPositional _c
          firstFragment: #F10
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        requiredPositional _e
          firstFragment: #F11
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        requiredPositional _f
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/a/b/b.dart::@typeAlias::F
      returnType: void
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
        #F1 c @19
          element: <testLibrary>::@topLevelVariable::c
          getter: #F2
          setter: #F3
        #F4 e @24
          element: <testLibrary>::@topLevelVariable::e
          getter: #F5
          setter: #F6
        #F7 f @29
          element: <testLibrary>::@topLevelVariable::f
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F1
        #F5 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F4
        #F8 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: package:test/a.dart::@typeAlias::F
          variable: #F7
      setters
        #F3 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F10 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F6 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F11 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F9 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        requiredPositional _c
          firstFragment: #F10
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        requiredPositional _e
          firstFragment: #F11
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        requiredPositional _f
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/a.dart::@typeAlias::F
      returnType: void
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
        #F1 c1 @20
          element: <testLibrary>::@topLevelVariable::c1
          getter: #F2
          setter: #F3
        #F4 c2 @27
          element: <testLibrary>::@topLevelVariable::c2
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic c1
          element: <testLibrary>::@getter::c1
          returnType: C1
          variable: #F1
        #F5 synthetic c2
          element: <testLibrary>::@getter::c2
          returnType: C2
          variable: #F4
      setters
        #F3 synthetic c1
          element: <testLibrary>::@setter::c1
          formalParameters
            #F7 _c1
              element: <testLibrary>::@setter::c1::@formalParameter::_c1
        #F6 synthetic c2
          element: <testLibrary>::@setter::c2
          formalParameters
            #F8 _c2
              element: <testLibrary>::@setter::c2::@formalParameter::_c2
  topLevelVariables
    c1
      reference: <testLibrary>::@topLevelVariable::c1
      firstFragment: #F1
      type: C1
      getter: <testLibrary>::@getter::c1
      setter: <testLibrary>::@setter::c1
    c2
      reference: <testLibrary>::@topLevelVariable::c2
      firstFragment: #F4
      type: C2
      getter: <testLibrary>::@getter::c2
      setter: <testLibrary>::@setter::c2
  getters
    synthetic static c1
      reference: <testLibrary>::@getter::c1
      firstFragment: #F2
      returnType: C1
      variable: <testLibrary>::@topLevelVariable::c1
    synthetic static c2
      reference: <testLibrary>::@getter::c2
      firstFragment: #F5
      returnType: C2
      variable: <testLibrary>::@topLevelVariable::c2
  setters
    synthetic static c1
      reference: <testLibrary>::@setter::c1
      firstFragment: #F3
      formalParameters
        requiredPositional _c1
          firstFragment: #F7
          type: C1
      returnType: void
    synthetic static c2
      reference: <testLibrary>::@setter::c2
      firstFragment: #F6
      formalParameters
        requiredPositional _c2
          firstFragment: #F8
          type: C2
      returnType: void
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
        #F1 c @21
          element: <testLibrary>::@topLevelVariable::c
          getter: #F2
          setter: #F3
        #F4 e @26
          element: <testLibrary>::@topLevelVariable::e
          getter: #F5
          setter: #F6
        #F7 f @31
          element: <testLibrary>::@topLevelVariable::f
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F1
        #F5 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F4
        #F8 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: package:test/a/b.dart::@typeAlias::F
          variable: #F7
      setters
        #F3 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F10 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F6 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F11 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F9 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/a/b.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/a/b.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        requiredPositional _c
          firstFragment: #F10
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        requiredPositional _e
          firstFragment: #F11
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        requiredPositional _f
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/a/b.dart::@typeAlias::F
      returnType: void
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
        #F1 c @19
          element: <testLibrary>::@topLevelVariable::c
          getter: #F2
          setter: #F3
        #F4 e @24
          element: <testLibrary>::@topLevelVariable::e
          getter: #F5
          setter: #F6
        #F7 f @29
          element: <testLibrary>::@topLevelVariable::f
          getter: #F8
          setter: #F9
      getters
        #F2 synthetic c
          element: <testLibrary>::@getter::c
          returnType: C
          variable: #F1
        #F5 synthetic e
          element: <testLibrary>::@getter::e
          returnType: E
          variable: #F4
        #F8 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: package:test/a.dart::@typeAlias::F
          variable: #F7
      setters
        #F3 synthetic c
          element: <testLibrary>::@setter::c
          formalParameters
            #F10 _c
              element: <testLibrary>::@setter::c::@formalParameter::_c
        #F6 synthetic e
          element: <testLibrary>::@setter::e
          formalParameters
            #F11 _e
              element: <testLibrary>::@setter::e::@formalParameter::_e
        #F9 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        requiredPositional _c
          firstFragment: #F10
          type: C
      returnType: void
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        requiredPositional _e
          firstFragment: #F11
          type: E
      returnType: void
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        requiredPositional _f
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/a.dart::@typeAlias::F
      returnType: void
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
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F2 f @15
          element: <testLibrary>::@topLevelVariable::f
          getter: #F3
          setter: #F4
      getters
        #F3 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
          variable: #F2
      setters
        #F4 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F5 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
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
        requiredPositional _f
          firstFragment: #F5
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
      returnType: void
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
        #F1 F @10
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @12
              element: #E0 T
            #F3 U @15
              element: #E1 U
      topLevelVariables
        #F4 f @39
          element: <testLibrary>::@topLevelVariable::f
          getter: #F5
          setter: #F6
      getters
        #F5 synthetic f
          element: <testLibrary>::@getter::f
          returnType: String Function(int)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                int
                String
          variable: #F4
      setters
        #F6 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F7 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
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
        requiredPositional _f
          firstFragment: #F7
          type: String Function(int)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                int
                String
      returnType: void
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
        #F1 F @10
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @12
              element: #E0 T
            #F3 U @15
              element: #E1 U
      topLevelVariables
        #F4 f @26
          element: <testLibrary>::@topLevelVariable::f
          getter: #F5
          setter: #F6
      getters
        #F5 synthetic f
          element: <testLibrary>::@getter::f
          returnType: dynamic Function(dynamic)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                dynamic
                dynamic
          variable: #F4
      setters
        #F6 synthetic f
          element: <testLibrary>::@setter::f
          formalParameters
            #F7 _f
              element: <testLibrary>::@setter::f::@formalParameter::_f
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
        requiredPositional _f
          firstFragment: #F7
          type: dynamic Function(dynamic)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                dynamic
                dynamic
      returnType: void
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
