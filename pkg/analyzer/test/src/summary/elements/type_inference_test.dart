// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_utilities/testing/test_support.dart';
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer f @6
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
      getters
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
  topLevelVariables
    final hasInitializer f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: V Function<U, V>(U, V)
      getter: <testLibraryFragment>::@getter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: V Function<U, V>(U, V)
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
    <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      parts
        part_0
          uri: package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        hasInitializer f @19
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::f
      getters
        synthetic get f
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::f#element
  topLevelVariables
    final hasInitializer f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
      type: double Function(int)
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::f
      returnType: double Function(int)
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
          fields
            hasInitializer f @21
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibraryFragment>::@class::C::@field::f#element
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get f
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      fields
        final hasInitializer f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          type: InvalidType
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
          returnType: InvalidType
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @43
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            V @45
              element: V@45
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
              typeNameOffset: 58
              formalParameters
                f @65
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::f#element
        class D @77
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          typeParameters
            T @79
              element: T@79
            U @81
              element: U@81
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
          typeParameters
            T @10
              element: T@10
      topLevelVariables
        hasInitializer x @118
          reference: <testLibraryFragment>::@topLevelVariable::x
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
                  baseElement: <testLibraryFragment>::@class::C::@constructor::new#element
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
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      functions
        f @96
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            U @98
              element: U@98
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        V
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            requiredPositional f
              type: D<V, U> Function<U>()
                alias: <testLibrary>::@typeAlias::F
                  typeArguments
                    V
    class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      typeParameters
        T
        U
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      typeParameters
        T
      aliasedType: D<T, U> Function<U>()
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: C<int>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: C<int>
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        U
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @38
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
              typeNameOffset: 50
              formalParameters
                f @54
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::f#element
        class D @66
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          typeParameters
            T @68
              element: T@68
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        hasInitializer x @101
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @105
              constructorName: ConstructorName
                type: NamedType
                  name: C @111
                  element2: <testLibrary>::@class::C
                  type: C
                element: <testLibraryFragment>::@class::C::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @112
                arguments
                  SimpleIdentifier
                    token: f @113
                    element: <testLibrary>::@function::f
                    staticType: D<T> Function<T>()
                rightParenthesis: ) @114
              staticType: C
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      functions
        f @79
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @81
              element: T@81
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            requiredPositional f
              type: D<T> Function<T>()
                alias: <testLibrary>::@typeAlias::F
    class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: D<T> Function<T>()
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: C
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: C
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
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
        class B @18
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
        class S @40
          reference: <testLibraryFragment>::@class::S
          element: <testLibrary>::@class::S
          typeParameters
            T @42
              element: T@42
          constructors
            new
              reference: <testLibraryFragment>::@class::S::@constructor::new
              element: <testLibraryFragment>::@class::S::@constructor::new#element
              typeName: S
              typeNameOffset: 59
              formalParameters
                _ @63
                  element: <testLibraryFragment>::@class::S::@constructor::new::@parameter::_#element
      topLevelVariables
        hasInitializer s @74
          reference: <testLibraryFragment>::@topLevelVariable::s
          element: <testLibrary>::@topLevelVariable::s
          getter2: <testLibraryFragment>::@getter::s
          setter2: <testLibraryFragment>::@setter::s
      getters
        synthetic get s
          reference: <testLibraryFragment>::@getter::s
          element: <testLibraryFragment>::@getter::s#element
      setters
        synthetic set s
          reference: <testLibraryFragment>::@setter::s
          element: <testLibraryFragment>::@setter::s#element
          formalParameters
            _s
              element: <testLibraryFragment>::@setter::s::@parameter::_s#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
    class S
      reference: <testLibrary>::@class::S
      firstFragment: <testLibraryFragment>::@class::S
      typeParameters
        T
          bound: A
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::S::@constructor::new
          formalParameters
            requiredPositional _
              type: T
  topLevelVariables
    hasInitializer s
      reference: <testLibrary>::@topLevelVariable::s
      firstFragment: <testLibraryFragment>::@topLevelVariable::s
      type: S<B>
      getter: <testLibraryFragment>::@getter::s#element
      setter: <testLibraryFragment>::@setter::s#element
  getters
    synthetic static get s
      firstFragment: <testLibraryFragment>::@getter::s
      returnType: S<B>
  setters
    synthetic static set s
      firstFragment: <testLibraryFragment>::@setter::s
      formalParameters
        requiredPositional _s
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            b @14
              reference: <testLibraryFragment>::@class::A::@field::b
              element: <testLibraryFragment>::@class::A::@field::b#element
              getter2: <testLibraryFragment>::@class::A::@getter::b
              setter2: <testLibraryFragment>::@class::A::@setter::b
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          getters
            synthetic get b
              reference: <testLibraryFragment>::@class::A::@getter::b
              element: <testLibraryFragment>::@class::A::@getter::b#element
          setters
            synthetic set b
              reference: <testLibraryFragment>::@class::A::@setter::b
              element: <testLibraryFragment>::@class::A::@setter::b#element
              formalParameters
                _b
                  element: <testLibraryFragment>::@class::A::@setter::b::@parameter::_b#element
        class B @25
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          fields
            synthetic c
              reference: <testLibraryFragment>::@class::B::@field::c
              element: <testLibraryFragment>::@class::B::@field::c#element
              getter2: <testLibraryFragment>::@class::B::@getter::c
              setter2: <testLibraryFragment>::@class::B::@setter::c
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
          getters
            get c @37
              reference: <testLibraryFragment>::@class::B::@getter::c
              element: <testLibraryFragment>::@class::B::@getter::c#element
          setters
            set c @59
              reference: <testLibraryFragment>::@class::B::@setter::c
              element: <testLibraryFragment>::@class::B::@setter::c#element
              formalParameters
                value @63
                  element: <testLibraryFragment>::@class::B::@setter::c::@parameter::value#element
        class C @81
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
        class D @92
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
      topLevelVariables
        hasInitializer a @111
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
          setter2: <testLibraryFragment>::@setter::a
        hasInitializer x @128
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set a
          reference: <testLibraryFragment>::@setter::a
          element: <testLibraryFragment>::@setter::a#element
          formalParameters
            _a
              element: <testLibraryFragment>::@setter::a::@parameter::_a#element
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        b
          firstFragment: <testLibraryFragment>::@class::A::@field::b
          type: B
          getter: <testLibraryFragment>::@class::A::@getter::b#element
          setter: <testLibraryFragment>::@class::A::@setter::b#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get b
          firstFragment: <testLibraryFragment>::@class::A::@getter::b
          returnType: B
      setters
        synthetic set b
          firstFragment: <testLibraryFragment>::@class::A::@setter::b
          formalParameters
            requiredPositional _b
              type: B
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        synthetic c
          firstFragment: <testLibraryFragment>::@class::B::@field::c
          type: C
          getter: <testLibraryFragment>::@class::B::@getter::c#element
          setter: <testLibraryFragment>::@class::B::@setter::c#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      getters
        get c
          firstFragment: <testLibraryFragment>::@class::B::@getter::c
          returnType: C
      setters
        set c
          firstFragment: <testLibraryFragment>::@class::B::@setter::c
          formalParameters
            requiredPositional value
              type: C
          returnType: void
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      supertype: C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
          superConstructor: <testLibraryFragment>::@class::C::@constructor::new#element
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: A
      getter: <testLibraryFragment>::@getter::a#element
      setter: <testLibraryFragment>::@setter::a#element
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: C
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: A
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: C
  setters
    synthetic static set a
      firstFragment: <testLibraryFragment>::@setter::a
      formalParameters
        requiredPositional _a
          type: A
      returnType: void
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
        hasInitializer y @40
          reference: <testLibraryFragment>::@topLevelVariable::y
          element: <testLibrary>::@topLevelVariable::y
          getter2: <testLibraryFragment>::@getter::y
          setter2: <testLibraryFragment>::@setter::y
        hasInitializer z @53
          reference: <testLibraryFragment>::@topLevelVariable::z
          element: <testLibrary>::@topLevelVariable::z
          getter2: <testLibraryFragment>::@getter::z
          setter2: <testLibraryFragment>::@setter::z
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
        synthetic get y
          reference: <testLibraryFragment>::@getter::y
          element: <testLibraryFragment>::@getter::y#element
        synthetic get z
          reference: <testLibraryFragment>::@getter::z
          element: <testLibraryFragment>::@getter::z#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
        synthetic set y
          reference: <testLibraryFragment>::@setter::y
          element: <testLibraryFragment>::@setter::y#element
          formalParameters
            _y
              element: <testLibraryFragment>::@setter::y::@parameter::_y#element
        synthetic set z
          reference: <testLibraryFragment>::@setter::z
          element: <testLibraryFragment>::@setter::z#element
          formalParameters
            _z
              element: <testLibraryFragment>::@setter::z::@parameter::_z#element
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Iterable<String>
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
    hasInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      type: List<int>
      getter: <testLibraryFragment>::@getter::y#element
      setter: <testLibraryFragment>::@setter::y#element
    hasInitializer z
      reference: <testLibrary>::@topLevelVariable::z
      firstFragment: <testLibraryFragment>::@topLevelVariable::z
      type: List<String>
      getter: <testLibraryFragment>::@getter::z#element
      setter: <testLibraryFragment>::@setter::z#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Iterable<String>
    synthetic static get y
      firstFragment: <testLibraryFragment>::@getter::y
      returnType: List<int>
    synthetic static get z
      firstFragment: <testLibraryFragment>::@getter::z
      returnType: List<String>
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: Iterable<String>
      returnType: void
    synthetic static set y
      firstFragment: <testLibraryFragment>::@setter::y
      formalParameters
        requiredPositional _y
          type: List<int>
      returnType: void
    synthetic static set z
      firstFragment: <testLibraryFragment>::@setter::z
      formalParameters
        requiredPositional _z
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            p @16
              reference: <testLibraryFragment>::@class::C::@field::p
              element: <testLibraryFragment>::@class::C::@field::p#element
              getter2: <testLibraryFragment>::@class::C::@getter::p
              setter2: <testLibraryFragment>::@class::C::@setter::p
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get p
              reference: <testLibraryFragment>::@class::C::@getter::p
              element: <testLibraryFragment>::@class::C::@getter::p#element
          setters
            synthetic set p
              reference: <testLibraryFragment>::@class::C::@setter::p
              element: <testLibraryFragment>::@class::C::@setter::p#element
              formalParameters
                _p
                  element: <testLibraryFragment>::@class::C::@setter::p::@parameter::_p#element
      topLevelVariables
        hasInitializer x @25
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
        hasInitializer y @40
          reference: <testLibraryFragment>::@topLevelVariable::y
          element: <testLibrary>::@topLevelVariable::y
          getter2: <testLibraryFragment>::@getter::y
          setter2: <testLibraryFragment>::@setter::y
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
        synthetic get y
          reference: <testLibraryFragment>::@getter::y
          element: <testLibraryFragment>::@getter::y#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
        synthetic set y
          reference: <testLibraryFragment>::@setter::y
          element: <testLibraryFragment>::@setter::y#element
          formalParameters
            _y
              element: <testLibraryFragment>::@setter::y::@parameter::_y#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        p
          firstFragment: <testLibraryFragment>::@class::C::@field::p
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::p#element
          setter: <testLibraryFragment>::@class::C::@setter::p#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get p
          firstFragment: <testLibraryFragment>::@class::C::@getter::p
          returnType: int
      setters
        synthetic set p
          firstFragment: <testLibraryFragment>::@class::C::@setter::p
          formalParameters
            requiredPositional _p
              type: int
          returnType: void
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: List<C>
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
    hasInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      type: Iterable<int>
      getter: <testLibraryFragment>::@getter::y#element
      setter: <testLibraryFragment>::@setter::y#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: List<C>
    synthetic static get y
      firstFragment: <testLibraryFragment>::@getter::y
      returnType: Iterable<int>
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: List<C>
      returnType: void
    synthetic static set y
      firstFragment: <testLibraryFragment>::@setter::y
      formalParameters
        requiredPositional _y
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
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            U @2
              element: U@2
            V @5
              element: V@5
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        U
        V
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            U @8
              element: U@8
            V @11
              element: V@11
          fields
            x @24
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
          constructors
            new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
              typeNameOffset: 29
          getters
            synthetic get x
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        U
        V
      fields
        final x
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          type: dynamic
          getter: <testLibraryFragment>::@class::C::@getter::x#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
          returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            U @8
              element: U@8
            V @11
              element: V@11
          fields
            synthetic x
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            get x @22
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        U
        V
      fields
        synthetic x
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          type: dynamic
          getter: <testLibraryFragment>::@class::C::@getter::x#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
          returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            f @15
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <testLibraryFragment>::@class::C::@method::f#element
              typeParameters
                U @17
                  element: U@17
                V @20
                  element: V@20
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          typeParameters
            U
            V
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            U @8
              element: U@8
            V @11
              element: V@11
          fields
            synthetic x
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          setters
            set x @27
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <testLibraryFragment>::@class::C::@setter::x#element
              formalParameters
                value @29
                  element: <testLibraryFragment>::@class::C::@setter::x::@parameter::value#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        U
        V
      fields
        synthetic x
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          type: dynamic
          setter: <testLibraryFragment>::@class::C::@setter::x#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      setters
        set x
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
          formalParameters
            requiredPositional hasImplicitType value
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
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @2
              element: T@2
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
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
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @2
              element: T@2
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            P @8
              element: P@8
          constructors
            factory new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
              typeNameOffset: 35
              formalParameters
                p @49
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::p#element
            _ @66
              reference: <testLibraryFragment>::@class::C::@constructor::_
              element: <testLibraryFragment>::@class::C::@constructor::_#element
              typeName: C
              typeNameOffset: 64
              periodOffset: 65
      topLevelVariables
        hasInitializer c @78
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        P
          bound: num
      constructors
        factory new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            requiredPositional p
              type: Iterable<P>
        _
          firstFragment: <testLibraryFragment>::@class::C::@constructor::_
  topLevelVariables
    hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C<num>
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C<num>
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            hasInitializer foo @25
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
            hasInitializer bar @56
              reference: <testLibraryFragment>::@class::A::@field::bar
              element: <testLibraryFragment>::@class::A::@field::bar#element
              getter2: <testLibraryFragment>::@class::A::@getter::bar
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
            synthetic get bar
              reference: <testLibraryFragment>::@class::A::@getter::bar
              element: <testLibraryFragment>::@class::A::@getter::bar#element
          methods
            baz @100
              reference: <testLibraryFragment>::@class::A::@method::baz
              element: <testLibraryFragment>::@class::A::@method::baz#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static final hasInitializer foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
        static final hasInitializer bar
          firstFragment: <testLibraryFragment>::@class::A::@field::bar
          type: int Function(double)
          getter: <testLibraryFragment>::@class::A::@getter::bar#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
          returnType: int
        synthetic static get bar
          firstFragment: <testLibraryFragment>::@class::A::@getter::bar
          returnType: int Function(double)
      methods
        static baz
          firstFragment: <testLibraryFragment>::@class::A::@method::baz
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
      functions
        m @4
          reference: <testLibraryFragment>::@function::m
          element: <testLibrary>::@function::m
          typeParameters
            T @6
              element: T@6
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int
      returnType: void
  functions
    m
      reference: <testLibrary>::@function::m
      firstFragment: <testLibraryFragment>::@function::m
      typeParameters
        T
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer m @19
          reference: <testLibraryFragment>::@topLevelVariable::m
          element: <testLibrary>::@topLevelVariable::m
          getter2: <testLibraryFragment>::@getter::m
          setter2: <testLibraryFragment>::@setter::m
        hasInitializer n @53
          reference: <testLibraryFragment>::@topLevelVariable::n
          element: <testLibrary>::@topLevelVariable::n
          getter2: <testLibraryFragment>::@getter::n
          setter2: <testLibraryFragment>::@setter::n
        hasInitializer x @73
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get m
          reference: <testLibraryFragment>::@getter::m
          element: <testLibraryFragment>::@getter::m#element
        synthetic get n
          reference: <testLibraryFragment>::@getter::n
          element: <testLibraryFragment>::@getter::n#element
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set m
          reference: <testLibraryFragment>::@setter::m
          element: <testLibraryFragment>::@setter::m#element
          formalParameters
            _m
              element: <testLibraryFragment>::@setter::m::@parameter::_m#element
        synthetic set n
          reference: <testLibraryFragment>::@setter::n
          element: <testLibraryFragment>::@setter::n#element
          formalParameters
            _n
              element: <testLibraryFragment>::@setter::n::@parameter::_n#element
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    hasInitializer m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      type: int Function<T>()?
      getter: <testLibraryFragment>::@getter::m#element
      setter: <testLibraryFragment>::@setter::m#element
    hasInitializer n
      reference: <testLibrary>::@topLevelVariable::n
      firstFragment: <testLibraryFragment>::@topLevelVariable::n
      type: int Function<T>()
      getter: <testLibraryFragment>::@getter::n#element
      setter: <testLibraryFragment>::@setter::n#element
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get m
      firstFragment: <testLibraryFragment>::@getter::m
      returnType: int Function<T>()?
    synthetic static get n
      firstFragment: <testLibraryFragment>::@getter::n
      returnType: int Function<T>()
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
  setters
    synthetic static set m
      firstFragment: <testLibraryFragment>::@setter::m
      formalParameters
        requiredPositional _m
          type: int Function<T>()?
      returnType: void
    synthetic static set n
      firstFragment: <testLibraryFragment>::@setter::n
      formalParameters
        requiredPositional _n
          type: int Function<T>()
      returnType: void
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:collection
      topLevelVariables
        hasInitializer m @30
          reference: <testLibraryFragment>::@topLevelVariable::m
          element: <testLibrary>::@topLevelVariable::m
          getter2: <testLibraryFragment>::@getter::m
          setter2: <testLibraryFragment>::@setter::m
      getters
        synthetic get m
          reference: <testLibraryFragment>::@getter::m
          element: <testLibraryFragment>::@getter::m#element
      setters
        synthetic set m
          reference: <testLibraryFragment>::@setter::m
          element: <testLibraryFragment>::@setter::m#element
          formalParameters
            _m
              element: <testLibraryFragment>::@setter::m::@parameter::_m#element
  topLevelVariables
    hasInitializer m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      type: HashMap<dynamic, dynamic>
      getter: <testLibraryFragment>::@getter::m#element
      setter: <testLibraryFragment>::@setter::m#element
  getters
    synthetic static get m
      firstFragment: <testLibraryFragment>::@getter::m
      returnType: HashMap<dynamic, dynamic>
  setters
    synthetic static set m
      firstFragment: <testLibraryFragment>::@setter::m
      formalParameters
        requiredPositional _m
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
          setter2: <testLibraryFragment>::@setter::a
        hasInitializer b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
          setter2: <testLibraryFragment>::@setter::b
        hasInitializer c @34
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        hasInitializer d @49
          reference: <testLibraryFragment>::@topLevelVariable::d
          element: <testLibrary>::@topLevelVariable::d
          getter2: <testLibraryFragment>::@getter::d
          setter2: <testLibraryFragment>::@setter::d
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get d
          reference: <testLibraryFragment>::@getter::d
          element: <testLibraryFragment>::@getter::d#element
      setters
        synthetic set a
          reference: <testLibraryFragment>::@setter::a
          element: <testLibraryFragment>::@setter::a#element
          formalParameters
            _a
              element: <testLibraryFragment>::@setter::a::@parameter::_a#element
        synthetic set b
          reference: <testLibraryFragment>::@setter::b
          element: <testLibraryFragment>::@setter::b#element
          formalParameters
            _b
              element: <testLibraryFragment>::@setter::b::@parameter::_b#element
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set d
          reference: <testLibraryFragment>::@setter::d
          element: <testLibraryFragment>::@setter::d#element
          formalParameters
            _d
              element: <testLibraryFragment>::@setter::d::@parameter::_d#element
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
      setter: <testLibraryFragment>::@setter::a#element
    hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      getter: <testLibraryFragment>::@getter::b#element
      setter: <testLibraryFragment>::@setter::b#element
    hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: dynamic
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    hasInitializer d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: <testLibraryFragment>::@topLevelVariable::d
      type: int
      getter: <testLibraryFragment>::@getter::d#element
      setter: <testLibraryFragment>::@setter::d#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: dynamic
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: dynamic
    synthetic static get d
      firstFragment: <testLibraryFragment>::@getter::d
      returnType: int
  setters
    synthetic static set a
      firstFragment: <testLibraryFragment>::@setter::a
      formalParameters
        requiredPositional _a
          type: dynamic
      returnType: void
    synthetic static set b
      firstFragment: <testLibraryFragment>::@setter::b
      formalParameters
        requiredPositional _b
          type: dynamic
      returnType: void
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: dynamic
      returnType: void
    synthetic static set d
      firstFragment: <testLibraryFragment>::@setter::d
      formalParameters
        requiredPositional _d
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @31
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            v @49
              reference: <testLibraryFragment>::@class::C::@field::v
              element: <testLibraryFragment>::@class::C::@field::v#element
              getter2: <testLibraryFragment>::@class::C::@getter::v
              setter2: <testLibraryFragment>::@class::C::@setter::v
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get v
              reference: <testLibraryFragment>::@class::C::@getter::v
              element: <testLibraryFragment>::@class::C::@getter::v#element
          setters
            synthetic set v
              reference: <testLibraryFragment>::@class::C::@setter::v
              element: <testLibraryFragment>::@class::C::@setter::v#element
              formalParameters
                _v
                  element: <testLibraryFragment>::@class::C::@setter::v::@parameter::_v#element
        class D @69
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          fields
            synthetic v
              reference: <testLibraryFragment>::@class::D::@field::v
              element: <testLibraryFragment>::@class::D::@field::v#element
              getter2: <testLibraryFragment>::@class::D::@getter::v
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
          getters
            get v @79
              reference: <testLibraryFragment>::@class::D::@getter::v
              element: <testLibraryFragment>::@class::D::@getter::v#element
      typeAliases
        F @12
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      fields
        v
          firstFragment: <testLibraryFragment>::@class::C::@field::v
          type: int Function(String)
            alias: <testLibrary>::@typeAlias::F
          getter: <testLibraryFragment>::@class::C::@getter::v#element
          setter: <testLibraryFragment>::@class::C::@setter::v#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::D::@constructor::new#element
      getters
        synthetic get v
          firstFragment: <testLibraryFragment>::@class::C::@getter::v
          returnType: int Function(String)
            alias: <testLibrary>::@typeAlias::F
      setters
        synthetic set v
          firstFragment: <testLibraryFragment>::@class::C::@setter::v
          formalParameters
            requiredPositional _v
              type: int Function(String)
                alias: <testLibrary>::@typeAlias::F
          returnType: void
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      fields
        synthetic v
          firstFragment: <testLibraryFragment>::@class::D::@field::v
          type: int Function(String)
            alias: <testLibrary>::@typeAlias::F
          getter: <testLibraryFragment>::@class::D::@getter::v#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      getters
        abstract get v
          firstFragment: <testLibraryFragment>::@class::D::@getter::v
          returnType: int Function(String)
            alias: <testLibrary>::@typeAlias::F
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int?
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int?
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: void Function()
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: void Function()
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: void Function()?
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: void Function()?
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
          fields
            v @37
              reference: <testLibraryFragment>::@class::C::@field::v
              element: <testLibraryFragment>::@class::C::@field::v#element
              getter2: <testLibraryFragment>::@class::C::@getter::v
              setter2: <testLibraryFragment>::@class::C::@setter::v
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get v
              reference: <testLibraryFragment>::@class::C::@getter::v
              element: <testLibraryFragment>::@class::C::@getter::v#element
          setters
            synthetic set v
              reference: <testLibraryFragment>::@class::C::@setter::v
              element: <testLibraryFragment>::@class::C::@setter::v#element
              formalParameters
                _v
                  element: <testLibraryFragment>::@class::C::@setter::v::@parameter::_v#element
        class D @57
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          typeParameters
            U @59
              element: U@59
            V @62
              element: V@62
          fields
            synthetic v
              reference: <testLibraryFragment>::@class::D::@field::v
              element: <testLibraryFragment>::@class::D::@field::v#element
              getter2: <testLibraryFragment>::@class::D::@getter::v
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
          getters
            get v @83
              reference: <testLibraryFragment>::@class::D::@getter::v
              element: <testLibraryFragment>::@class::D::@getter::v#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      supertype: D<int, T>
      fields
        v
          firstFragment: <testLibraryFragment>::@class::C::@field::v
          hasEnclosingTypeParameterReference: true
          type: Map<T, int>
          getter: <testLibraryFragment>::@class::C::@getter::v#element
          setter: <testLibraryFragment>::@class::C::@setter::v#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::D::@constructor::new#element
      getters
        synthetic get v
          firstFragment: <testLibraryFragment>::@class::C::@getter::v
          hasEnclosingTypeParameterReference: true
          returnType: Map<T, int>
      setters
        synthetic set v
          firstFragment: <testLibraryFragment>::@class::C::@setter::v
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _v
              type: Map<T, int>
          returnType: void
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      typeParameters
        U
        V
      fields
        synthetic v
          firstFragment: <testLibraryFragment>::@class::D::@field::v
          hasEnclosingTypeParameterReference: true
          type: Map<V, U>
          getter: <testLibraryFragment>::@class::D::@getter::v#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      getters
        abstract get v
          firstFragment: <testLibraryFragment>::@class::D::@getter::v
          hasEnclosingTypeParameterReference: true
          returnType: Map<V, U>
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
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        hasInitializer v @53
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        synthetic set v
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
      functions
        h @33
          reference: <testLibraryFragment>::@function::h
          element: <testLibrary>::@function::h
          formalParameters
            f @37
              element: <testLibraryFragment>::@function::h::@parameter::f#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: void Function(int Function(String))
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: dynamic
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: dynamic
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: dynamic
      returnType: void
  functions
    h
      reference: <testLibrary>::@function::h
      firstFragment: <testLibraryFragment>::@function::h
      formalParameters
        requiredPositional f
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
            U @11
              element: U@11
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            f @41
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <testLibraryFragment>::@class::C::@method::f#element
              formalParameters
                x @47
                  element: <testLibraryFragment>::@class::C::@method::f::@parameter::x#element
                g @50
                  element: <testLibraryFragment>::@class::C::@method::f::@parameter::g#element
        class D @73
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          typeParameters
            V @75
              element: V@75
            W @78
              element: W@78
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
          methods
            f @90
              reference: <testLibraryFragment>::@class::D::@method::f
              element: <testLibraryFragment>::@class::D::@method::f#element
              formalParameters
                x @96
                  element: <testLibraryFragment>::@class::D::@method::f::@parameter::x#element
                g @101
                  element: <testLibraryFragment>::@class::D::@method::f::@parameter::g#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
        U
      supertype: D<U, int>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::D::@constructor::new#element
      methods
        f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional x
              type: int
            requiredPositional hasImplicitType g
              type: int Function(U)
          returnType: void
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      typeParameters
        V
        W
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      methods
        abstract f
          firstFragment: <testLibraryFragment>::@class::D::@method::f
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional x
              type: int
            requiredPositional g
              type: W Function(V)
              formalParameters
                requiredPositional s
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      classes
        class C @23
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            f @44
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <testLibraryFragment>::@class::C::@method::f#element
              formalParameters
                x @50
                  element: <testLibraryFragment>::@class::C::@method::f::@parameter::x#element
                g @53
                  element: <testLibraryFragment>::@class::C::@method::f::@parameter::g#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: package:test/a.dart::<fragment>::@class::D::@constructor::new#element
      methods
        f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          formalParameters
            requiredPositional x
              type: int
            requiredPositional hasImplicitType g
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            f @25
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <testLibraryFragment>::@class::C::@method::f#element
              formalParameters
                x @31
                  element: <testLibraryFragment>::@class::C::@method::f::@parameter::x#element
                g @34
                  element: <testLibraryFragment>::@class::C::@method::f::@parameter::g#element
        class D @57
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
          methods
            f @66
              reference: <testLibraryFragment>::@class::D::@method::f
              element: <testLibraryFragment>::@class::D::@method::f#element
              formalParameters
                x @72
                  element: <testLibraryFragment>::@class::D::@method::f::@parameter::x#element
                g @79
                  element: <testLibraryFragment>::@class::D::@method::f::@parameter::g#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::D::@constructor::new#element
      methods
        f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          formalParameters
            requiredPositional x
              type: int
            requiredPositional hasImplicitType g
              type: int Function(String)
          returnType: void
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      methods
        abstract f
          firstFragment: <testLibraryFragment>::@class::D::@method::f
          formalParameters
            requiredPositional x
              type: int
            requiredPositional g
              type: int Function(String)
              formalParameters
                requiredPositional s
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @40
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        synthetic set v
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            g @7
              element: <testLibraryFragment>::@function::f::@parameter::g#element
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: dynamic
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: dynamic
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: dynamic
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional g
          type: void Function(int, void Function())
          formalParameters
            requiredPositional x
              type: int
            requiredPositional h
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @42
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        synthetic set v
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            default g @8
              reference: <testLibraryFragment>::@function::f::@parameter::g
              element: <testLibraryFragment>::@function::f::@parameter::g#element
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: dynamic
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: dynamic
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: dynamic
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalNamed g
          firstFragment: <testLibraryFragment>::@function::f::@parameter::g
          type: void Function(int, void Function())
          formalParameters
            requiredPositional x
              type: int
            requiredPositional h
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            synthetic f
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibraryFragment>::@class::C::@field::f#element
              setter2: <testLibraryFragment>::@class::C::@setter::f
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          setters
            set f @29
              reference: <testLibraryFragment>::@class::C::@setter::f
              element: <testLibraryFragment>::@class::C::@setter::f#element
              formalParameters
                g @31
                  element: <testLibraryFragment>::@class::C::@setter::f::@parameter::g#element
        class D @54
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          fields
            synthetic f
              reference: <testLibraryFragment>::@class::D::@field::f
              element: <testLibraryFragment>::@class::D::@field::f#element
              setter2: <testLibraryFragment>::@class::D::@setter::f
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
          setters
            set f @67
              reference: <testLibraryFragment>::@class::D::@setter::f
              element: <testLibraryFragment>::@class::D::@setter::f#element
              formalParameters
                g @73
                  element: <testLibraryFragment>::@class::D::@setter::f::@parameter::g#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      fields
        synthetic f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          type: int Function(String)
          setter: <testLibraryFragment>::@class::C::@setter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::D::@constructor::new#element
      setters
        set f
          firstFragment: <testLibraryFragment>::@class::C::@setter::f
          formalParameters
            requiredPositional hasImplicitType g
              type: int Function(String)
          returnType: void
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      fields
        synthetic f
          firstFragment: <testLibraryFragment>::@class::D::@field::f
          type: int Function(String)
          setter: <testLibraryFragment>::@class::D::@setter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      setters
        abstract set f
          firstFragment: <testLibraryFragment>::@class::D::@setter::f
          formalParameters
            requiredPositional g
              type: int Function(String)
              formalParameters
                requiredPositional s
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      classes
        class B @23
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
          methods
            m @39
              reference: <testLibraryFragment>::@class::B::@method::m
              element: <testLibraryFragment>::@class::B::@method::m#element
              formalParameters
                p @41
                  element: <testLibraryFragment>::@class::B::@method::m::@parameter::p#element
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      methods
        m
          firstFragment: <testLibraryFragment>::@class::B::@method::m
          formalParameters
            requiredPositional hasImplicitType p
              type: Stream<dynamic>
          returnType: dynamic
''');
    var b = library.classes[0];
    var p = b.methods2[0].formalParameters[0];
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 12
            named @21
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              typeName: A
              typeNameOffset: 19
              periodOffset: 20
      topLevelVariables
        hasInitializer a1 @36
          reference: <testLibraryFragment>::@topLevelVariable::a1
          element: <testLibrary>::@topLevelVariable::a1
          getter2: <testLibraryFragment>::@getter::a1
          setter2: <testLibraryFragment>::@setter::a1
        hasInitializer a2 @50
          reference: <testLibraryFragment>::@topLevelVariable::a2
          element: <testLibrary>::@topLevelVariable::a2
          getter2: <testLibraryFragment>::@getter::a2
          setter2: <testLibraryFragment>::@setter::a2
      getters
        synthetic get a1
          reference: <testLibraryFragment>::@getter::a1
          element: <testLibraryFragment>::@getter::a1#element
        synthetic get a2
          reference: <testLibraryFragment>::@getter::a2
          element: <testLibraryFragment>::@getter::a2#element
      setters
        synthetic set a1
          reference: <testLibraryFragment>::@setter::a1
          element: <testLibraryFragment>::@setter::a1#element
          formalParameters
            _a1
              element: <testLibraryFragment>::@setter::a1::@parameter::_a1#element
        synthetic set a2
          reference: <testLibraryFragment>::@setter::a2
          element: <testLibraryFragment>::@setter::a2#element
          formalParameters
            _a2
              element: <testLibraryFragment>::@setter::a2::@parameter::_a2#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
        named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
  topLevelVariables
    hasInitializer a1
      reference: <testLibrary>::@topLevelVariable::a1
      firstFragment: <testLibraryFragment>::@topLevelVariable::a1
      type: A
      getter: <testLibraryFragment>::@getter::a1#element
      setter: <testLibraryFragment>::@setter::a1#element
    hasInitializer a2
      reference: <testLibrary>::@topLevelVariable::a2
      firstFragment: <testLibraryFragment>::@topLevelVariable::a2
      type: A
      getter: <testLibraryFragment>::@getter::a2#element
      setter: <testLibraryFragment>::@setter::a2#element
  getters
    synthetic static get a1
      firstFragment: <testLibraryFragment>::@getter::a1
      returnType: A
    synthetic static get a2
      firstFragment: <testLibraryFragment>::@getter::a2
      returnType: A
  setters
    synthetic static set a1
      firstFragment: <testLibraryFragment>::@setter::a1
      formalParameters
        requiredPositional _a1
          type: A
      returnType: void
    synthetic static set a2
      firstFragment: <testLibraryFragment>::@setter::a2
      formalParameters
        requiredPositional _a2
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
      prefixes
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      topLevelVariables
        hasInitializer a1 @30
          reference: <testLibraryFragment>::@topLevelVariable::a1
          element: <testLibrary>::@topLevelVariable::a1
          getter2: <testLibraryFragment>::@getter::a1
          setter2: <testLibraryFragment>::@setter::a1
        hasInitializer a2 @48
          reference: <testLibraryFragment>::@topLevelVariable::a2
          element: <testLibrary>::@topLevelVariable::a2
          getter2: <testLibraryFragment>::@getter::a2
          setter2: <testLibraryFragment>::@setter::a2
      getters
        synthetic get a1
          reference: <testLibraryFragment>::@getter::a1
          element: <testLibraryFragment>::@getter::a1#element
        synthetic get a2
          reference: <testLibraryFragment>::@getter::a2
          element: <testLibraryFragment>::@getter::a2#element
      setters
        synthetic set a1
          reference: <testLibraryFragment>::@setter::a1
          element: <testLibraryFragment>::@setter::a1#element
          formalParameters
            _a1
              element: <testLibraryFragment>::@setter::a1::@parameter::_a1#element
        synthetic set a2
          reference: <testLibraryFragment>::@setter::a2
          element: <testLibraryFragment>::@setter::a2#element
          formalParameters
            _a2
              element: <testLibraryFragment>::@setter::a2::@parameter::_a2#element
  topLevelVariables
    hasInitializer a1
      reference: <testLibrary>::@topLevelVariable::a1
      firstFragment: <testLibraryFragment>::@topLevelVariable::a1
      type: A
      getter: <testLibraryFragment>::@getter::a1#element
      setter: <testLibraryFragment>::@setter::a1#element
    hasInitializer a2
      reference: <testLibrary>::@topLevelVariable::a2
      firstFragment: <testLibraryFragment>::@topLevelVariable::a2
      type: A
      getter: <testLibraryFragment>::@getter::a2#element
      setter: <testLibraryFragment>::@setter::a2#element
  getters
    synthetic static get a1
      firstFragment: <testLibraryFragment>::@getter::a1
      returnType: A
    synthetic static get a2
      firstFragment: <testLibraryFragment>::@getter::a2
      returnType: A
  setters
    synthetic static set a1
      firstFragment: <testLibraryFragment>::@setter::a1
      formalParameters
        requiredPositional _a1
          type: A
      returnType: void
    synthetic static set a2
      firstFragment: <testLibraryFragment>::@setter::a2
      formalParameters
        requiredPositional _a2
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @71
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        synthetic set v
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
      functions
        f @4
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            x @10
              element: <testLibraryFragment>::@function::f::@parameter::x#element
        g @39
          reference: <testLibraryFragment>::@function::g
          element: <testLibrary>::@function::g
          formalParameters
            x @45
              element: <testLibraryFragment>::@function::g::@parameter::x#element
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: List<Object Function(int Function(String))>
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: List<Object Function(int Function(String))>
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: List<Object Function(int Function(String))>
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional x
          type: int Function(String)
          formalParameters
            requiredPositional y
              type: String
      returnType: int
    g
      reference: <testLibrary>::@function::g
      firstFragment: <testLibraryFragment>::@function::g
      formalParameters
        requiredPositional x
          type: int Function(String)
          formalParameters
            requiredPositional y
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @15
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          methods
            m @25
              reference: <testLibraryFragment>::@class::A::@method::m
              element: <testLibraryFragment>::@class::A::@method::m#element
        class B @48
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
          methods
            m @61
              reference: <testLibraryFragment>::@class::B::@method::m
              element: <testLibraryFragment>::@class::B::@method::m#element
        class C @84
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
        class D @121
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          fields
            f @141
              reference: <testLibraryFragment>::@class::D::@field::f
              element: <testLibraryFragment>::@class::D::@field::f#element
              getter2: <testLibraryFragment>::@class::D::@getter::f
              setter2: <testLibraryFragment>::@class::D::@setter::f
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
          getters
            synthetic get f
              reference: <testLibraryFragment>::@class::D::@getter::f
              element: <testLibraryFragment>::@class::D::@getter::f#element
          setters
            synthetic set f
              reference: <testLibraryFragment>::@class::D::@setter::f
              element: <testLibraryFragment>::@class::D::@setter::f#element
              formalParameters
                _f
                  element: <testLibraryFragment>::@class::D::@setter::f::@parameter::_f#element
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        abstract m
          firstFragment: <testLibraryFragment>::@class::A::@method::m
          returnType: int
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      methods
        abstract m
          firstFragment: <testLibraryFragment>::@class::B::@method::m
          returnType: String
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      interfaces
        A
        B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      supertype: C
      fields
        f
          firstFragment: <testLibraryFragment>::@class::D::@field::f
          type: dynamic
          getter: <testLibraryFragment>::@class::D::@getter::f#element
          setter: <testLibraryFragment>::@class::D::@setter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
          superConstructor: <testLibraryFragment>::@class::C::@constructor::new#element
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::D::@getter::f
          returnType: dynamic
      setters
        synthetic set f
          firstFragment: <testLibraryFragment>::@class::D::@setter::f
          formalParameters
            requiredPositional _f
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
          methods
            call @19
              reference: <testLibraryFragment>::@class::A::@method::call
              element: <testLibraryFragment>::@class::A::@method::call#element
        class B @42
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          fields
            a @50
              reference: <testLibraryFragment>::@class::B::@field::a
              element: <testLibraryFragment>::@class::B::@field::a#element
              getter2: <testLibraryFragment>::@class::B::@getter::a
              setter2: <testLibraryFragment>::@class::B::@setter::a
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
          getters
            synthetic get a
              reference: <testLibraryFragment>::@class::B::@getter::a
              element: <testLibraryFragment>::@class::B::@getter::a#element
          setters
            synthetic set a
              reference: <testLibraryFragment>::@class::B::@setter::a
              element: <testLibraryFragment>::@class::B::@setter::a#element
              formalParameters
                _a
                  element: <testLibraryFragment>::@class::B::@setter::a::@parameter::_a#element
      topLevelVariables
        hasInitializer c @59
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        call
          firstFragment: <testLibraryFragment>::@class::A::@method::call
          returnType: double
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        a
          firstFragment: <testLibraryFragment>::@class::B::@field::a
          type: A
          getter: <testLibraryFragment>::@class::B::@getter::a#element
          setter: <testLibraryFragment>::@class::B::@setter::a#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      getters
        synthetic get a
          firstFragment: <testLibraryFragment>::@class::B::@getter::a
          returnType: A
      setters
        synthetic set a
          firstFragment: <testLibraryFragment>::@class::B::@setter::a
          formalParameters
            requiredPositional _a
              type: A
          returnType: void
  topLevelVariables
    hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: double
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: double
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
          setter2: <testLibraryFragment>::@setter::a
        hasInitializer b @42
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
          setter2: <testLibraryFragment>::@setter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
      setters
        synthetic set a
          reference: <testLibraryFragment>::@setter::a
          element: <testLibraryFragment>::@setter::a#element
          formalParameters
            _a
              element: <testLibraryFragment>::@setter::a::@parameter::_a#element
        synthetic set b
          reference: <testLibraryFragment>::@setter::b
          element: <testLibraryFragment>::@setter::b#element
          formalParameters
            _b
              element: <testLibraryFragment>::@setter::b::@parameter::_b#element
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int Function()
      getter: <testLibraryFragment>::@getter::a#element
      setter: <testLibraryFragment>::@setter::a#element
    hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: int
      getter: <testLibraryFragment>::@getter::b#element
      setter: <testLibraryFragment>::@setter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int Function()
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: int
  setters
    synthetic static set a
      firstFragment: <testLibraryFragment>::@setter::a
      formalParameters
        requiredPositional _a
          type: int Function()
      returnType: void
    synthetic static set b
      firstFragment: <testLibraryFragment>::@setter::b
      formalParameters
        requiredPositional _b
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart deferred as a @28
      prefixes
        <testLibraryFragment>::@prefix2::a
          fragments: @28
      topLevelVariables
        hasInitializer x @35
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Future<dynamic> Function()
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Future<dynamic> Function()
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int Function(int Function(String))
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int Function(int Function(String))
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int Function(int Function(String))
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int Function(int Function(String))
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer y @21
          reference: <testLibraryFragment>::@topLevelVariable::y
          element: <testLibrary>::@topLevelVariable::y
          getter2: <testLibraryFragment>::@getter::y
          setter2: <testLibraryFragment>::@setter::y
      getters
        synthetic get y
          reference: <testLibraryFragment>::@getter::y
          element: <testLibraryFragment>::@getter::y#element
      setters
        synthetic set y
          reference: <testLibraryFragment>::@setter::y
          element: <testLibraryFragment>::@setter::y#element
          formalParameters
            _y
              element: <testLibraryFragment>::@setter::y::@parameter::_y#element
  topLevelVariables
    hasInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      type: int
      getter: <testLibraryFragment>::@getter::y#element
      setter: <testLibraryFragment>::@setter::y#element
  getters
    synthetic static get y
      firstFragment: <testLibraryFragment>::@getter::y
      returnType: int
  setters
    synthetic static set y
      firstFragment: <testLibraryFragment>::@setter::y
      formalParameters
        requiredPositional _y
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            hasInitializer x @25
              reference: <testLibraryFragment>::@class::A::@field::x
              element: <testLibraryFragment>::@class::A::@field::x#element
              getter2: <testLibraryFragment>::@class::A::@getter::x
            hasInitializer y @51
              reference: <testLibraryFragment>::@class::A::@field::y
              element: <testLibraryFragment>::@class::A::@field::y#element
              getter2: <testLibraryFragment>::@class::A::@getter::y
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          getters
            synthetic get x
              reference: <testLibraryFragment>::@class::A::@getter::x
              element: <testLibraryFragment>::@class::A::@getter::x#element
            synthetic get y
              reference: <testLibraryFragment>::@class::A::@getter::y
              element: <testLibraryFragment>::@class::A::@getter::y#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static final hasInitializer x
          firstFragment: <testLibraryFragment>::@class::A::@field::x
          type: dynamic
          getter: <testLibraryFragment>::@class::A::@getter::x#element
        static final hasInitializer y
          firstFragment: <testLibraryFragment>::@class::A::@field::y
          type: dynamic
          getter: <testLibraryFragment>::@class::A::@getter::y#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic static get x
          firstFragment: <testLibraryFragment>::@class::A::@getter::x
          returnType: dynamic
        synthetic static get y
          firstFragment: <testLibraryFragment>::@class::A::@getter::y
          returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            hasInitializer a @25
              reference: <testLibraryFragment>::@class::A::@field::a
              element: <testLibraryFragment>::@class::A::@field::a#element
              getter2: <testLibraryFragment>::@class::A::@getter::a
            hasInitializer b @49
              reference: <testLibraryFragment>::@class::A::@field::b
              element: <testLibraryFragment>::@class::A::@field::b#element
              getter2: <testLibraryFragment>::@class::A::@getter::b
            hasInitializer c @66
              reference: <testLibraryFragment>::@class::A::@field::c
              element: <testLibraryFragment>::@class::A::@field::c#element
              getter2: <testLibraryFragment>::@class::A::@getter::c
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          getters
            synthetic get a
              reference: <testLibraryFragment>::@class::A::@getter::a
              element: <testLibraryFragment>::@class::A::@getter::a#element
            synthetic get b
              reference: <testLibraryFragment>::@class::A::@getter::b
              element: <testLibraryFragment>::@class::A::@getter::b#element
            synthetic get c
              reference: <testLibraryFragment>::@class::A::@getter::c
              element: <testLibraryFragment>::@class::A::@getter::c#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static final hasInitializer a
          firstFragment: <testLibraryFragment>::@class::A::@field::a
          type: dynamic
          getter: <testLibraryFragment>::@class::A::@getter::a#element
        static final hasInitializer b
          firstFragment: <testLibraryFragment>::@class::A::@field::b
          type: A
          getter: <testLibraryFragment>::@class::A::@getter::b#element
        final hasInitializer c
          firstFragment: <testLibraryFragment>::@class::A::@field::c
          type: dynamic
          getter: <testLibraryFragment>::@class::A::@getter::c#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@class::A::@getter::a
          returnType: dynamic
        synthetic static get b
          firstFragment: <testLibraryFragment>::@class::A::@getter::b
          returnType: A
        synthetic get c
          firstFragment: <testLibraryFragment>::@class::A::@getter::c
          returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: T@8
          fields
            value @17
              reference: <testLibraryFragment>::@class::A::@field::value
              element: <testLibraryFragment>::@class::A::@field::value#element
              getter2: <testLibraryFragment>::@class::A::@getter::value
              setter2: <testLibraryFragment>::@class::A::@setter::value
          constructors
            new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 27
              formalParameters
                this.value @34
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::value#element
          getters
            synthetic get value
              reference: <testLibraryFragment>::@class::A::@getter::value
              element: <testLibraryFragment>::@class::A::@getter::value#element
          setters
            synthetic set value
              reference: <testLibraryFragment>::@class::A::@setter::value
              element: <testLibraryFragment>::@class::A::@setter::value#element
              formalParameters
                _value
                  element: <testLibraryFragment>::@class::A::@setter::value::@parameter::_value#element
        class B @51
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          fields
            hasInitializer a @61
              reference: <testLibraryFragment>::@class::B::@field::a
              element: <testLibraryFragment>::@class::B::@field::a#element
              getter2: <testLibraryFragment>::@class::B::@getter::a
              setter2: <testLibraryFragment>::@class::B::@setter::a
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
          getters
            synthetic get a
              reference: <testLibraryFragment>::@class::B::@getter::a
              element: <testLibraryFragment>::@class::B::@getter::a#element
          setters
            synthetic set a
              reference: <testLibraryFragment>::@class::B::@setter::a
              element: <testLibraryFragment>::@class::B::@setter::a#element
              formalParameters
                _a
                  element: <testLibraryFragment>::@class::B::@setter::a::@parameter::_a#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      fields
        value
          firstFragment: <testLibraryFragment>::@class::A::@field::value
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibraryFragment>::@class::A::@getter::value#element
          setter: <testLibraryFragment>::@class::A::@setter::value#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType value
              type: T
      getters
        synthetic get value
          firstFragment: <testLibraryFragment>::@class::A::@getter::value
          hasEnclosingTypeParameterReference: true
          returnType: T
      setters
        synthetic set value
          firstFragment: <testLibraryFragment>::@class::A::@setter::value
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _value
              type: T
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        hasInitializer a
          firstFragment: <testLibraryFragment>::@class::B::@field::a
          type: A<String>
          getter: <testLibraryFragment>::@class::B::@getter::a#element
          setter: <testLibraryFragment>::@class::B::@setter::a#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      getters
        synthetic get a
          firstFragment: <testLibraryFragment>::@class::B::@getter::a
          returnType: A<String>
      setters
        synthetic set a
          firstFragment: <testLibraryFragment>::@class::B::@setter::a
          formalParameters
            requiredPositional _a
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: T@8
          fields
            value @17
              reference: <testLibraryFragment>::@class::A::@field::value
              element: <testLibraryFragment>::@class::A::@field::value#element
              getter2: <testLibraryFragment>::@class::A::@getter::value
              setter2: <testLibraryFragment>::@class::A::@setter::value
          constructors
            new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 27
              formalParameters
                this.value @34
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::value#element
          getters
            synthetic get value
              reference: <testLibraryFragment>::@class::A::@getter::value
              element: <testLibraryFragment>::@class::A::@getter::value#element
          setters
            synthetic set value
              reference: <testLibraryFragment>::@class::A::@setter::value
              element: <testLibraryFragment>::@class::A::@setter::value#element
              formalParameters
                _value
                  element: <testLibraryFragment>::@class::A::@setter::value::@parameter::_value#element
        class B @51
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T @53
              element: T@53
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
              formalParameters
                value (offset=-1)
                  element: <testLibraryFragment>::@class::B::@constructor::new::@parameter::value#element
        class C @78
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasInitializer a @88
              reference: <testLibraryFragment>::@class::C::@field::a
              element: <testLibraryFragment>::@class::C::@field::a#element
              getter2: <testLibraryFragment>::@class::C::@getter::a
              setter2: <testLibraryFragment>::@class::C::@setter::a
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get a
              reference: <testLibraryFragment>::@class::C::@getter::a
              element: <testLibraryFragment>::@class::C::@getter::a#element
          setters
            synthetic set a
              reference: <testLibraryFragment>::@class::C::@setter::a
              element: <testLibraryFragment>::@class::C::@setter::a#element
              formalParameters
                _a
                  element: <testLibraryFragment>::@class::C::@setter::a::@parameter::_a#element
      mixins
        mixin M @112
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      fields
        value
          firstFragment: <testLibraryFragment>::@class::A::@field::value
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibraryFragment>::@class::A::@getter::value#element
          setter: <testLibraryFragment>::@class::A::@setter::value#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType value
              type: T
      getters
        synthetic get value
          firstFragment: <testLibraryFragment>::@class::A::@getter::value
          hasEnclosingTypeParameterReference: true
          returnType: T
      setters
        synthetic set value
          firstFragment: <testLibraryFragment>::@class::A::@setter::value
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _value
              type: T
          returnType: void
    class alias B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      supertype: A<T>
      mixins
        M
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          formalParameters
            requiredPositional final value
              type: T
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: value @-1
                    element: <testLibraryFragment>::@class::B::@constructor::new::@parameter::value#element
                    staticType: T
                rightParenthesis: ) @0
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        hasInitializer a
          firstFragment: <testLibraryFragment>::@class::C::@field::a
          type: B<int>
          getter: <testLibraryFragment>::@class::C::@getter::a#element
          setter: <testLibraryFragment>::@class::C::@setter::a#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get a
          firstFragment: <testLibraryFragment>::@class::C::@getter::a
          returnType: B<int>
      setters
        synthetic set a
          firstFragment: <testLibraryFragment>::@class::C::@setter::a
          formalParameters
            requiredPositional _a
              type: B<int>
          returnType: void
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: T@8
          fields
            hasInitializer f @19
              reference: <testLibraryFragment>::@class::A::@field::f
              element: <testLibraryFragment>::@class::A::@field::f#element
              getter2: <testLibraryFragment>::@class::A::@getter::f
              setter2: <testLibraryFragment>::@class::A::@setter::f
          constructors
            new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 28
              formalParameters
                this.f @35
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f#element
          getters
            synthetic get f
              reference: <testLibraryFragment>::@class::A::@getter::f
              element: <testLibraryFragment>::@class::A::@getter::f#element
          setters
            synthetic set f
              reference: <testLibraryFragment>::@class::A::@setter::f
              element: <testLibraryFragment>::@class::A::@setter::f#element
              formalParameters
                _f
                  element: <testLibraryFragment>::@class::A::@setter::f::@parameter::_f#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      fields
        hasInitializer f
          firstFragment: <testLibraryFragment>::@class::A::@field::f
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::f#element
          setter: <testLibraryFragment>::@class::A::@setter::f#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType f
              type: int
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::A::@getter::f
          returnType: int
      setters
        synthetic set f
          firstFragment: <testLibraryFragment>::@class::A::@setter::f
          formalParameters
            requiredPositional _f
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 12
              formalParameters
                _ @14
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::_#element
      topLevelVariables
        hasInitializer a @26
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @48
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional hasImplicitType _
              type: dynamic
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
        package:test/b.dart
      topLevelVariables
        hasInitializer v @38
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        synthetic set v
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: InvalidType
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: InvalidType
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: dynamic Function(dynamic) Function(dynamic)
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: dynamic Function(dynamic) Function(dynamic)
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int Function(int) Function(int)
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int Function(int) Function(int)
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: dynamic Function([dynamic])
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: dynamic Function([dynamic])
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
        hasInitializer c @32
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      getter: <testLibraryFragment>::@getter::b#element
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: dynamic
      getter: <testLibraryFragment>::@getter::c#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: dynamic
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
        hasInitializer c @32
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      getter: <testLibraryFragment>::@getter::b#element
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: dynamic
      getter: <testLibraryFragment>::@getter::c#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: dynamic
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
        hasInitializer c @36
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
        hasInitializer d @49
          reference: <testLibraryFragment>::@topLevelVariable::d
          element: <testLibrary>::@topLevelVariable::d
          getter2: <testLibraryFragment>::@getter::d
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get d
          reference: <testLibraryFragment>::@getter::d
          element: <testLibraryFragment>::@getter::d#element
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      getter: <testLibraryFragment>::@getter::b#element
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: dynamic
      getter: <testLibraryFragment>::@getter::c#element
    final hasInitializer d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: <testLibraryFragment>::@topLevelVariable::d
      type: dynamic
      getter: <testLibraryFragment>::@getter::d#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: dynamic
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: dynamic
    synthetic static get d
      firstFragment: <testLibraryFragment>::@getter::d
      returnType: dynamic
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
        hasInitializer b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
        hasInitializer c @36
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: dynamic
      getter: <testLibraryFragment>::@getter::b#element
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: dynamic
      getter: <testLibraryFragment>::@getter::c#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: dynamic
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: dynamic
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
        class B @18
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
        class C @40
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @42
              element: T@42
          fields
            f @67
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibraryFragment>::@class::C::@field::f#element
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
              typeNameOffset: 78
              formalParameters
                this.f @85
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::f#element
          getters
            synthetic get f
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
      topLevelVariables
        hasInitializer b @98
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
        hasInitializer c @113
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
      getters
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: A
      fields
        final f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType f
              type: T
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
          hasEnclosingTypeParameterReference: true
          returnType: T
  topLevelVariables
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: B
      getter: <testLibraryFragment>::@getter::b#element
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C<B>
      getter: <testLibraryFragment>::@getter::c#element
  getters
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: B
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C<B>
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
    <testLibraryFragment>
      element: <testLibrary>
      extensions
        extension <null-name> (offset=0)
          reference: <testLibraryFragment>::@extension::0
          element: <testLibrary>::@extension::0
          fields
            synthetic foo
              reference: <testLibraryFragment>::@extension::0::@field::foo
              element: <testLibraryFragment>::@extension::0::@field::foo#element
              getter2: <testLibraryFragment>::@extension::0::@getter::foo
          getters
            get foo @32
              reference: <testLibraryFragment>::@extension::0::@getter::foo
              element: <testLibraryFragment>::@extension::0::@getter::foo#element
      topLevelVariables
        hasInitializer v @48
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        synthetic set v
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  extensions
    extension <null-name>
      reference: <testLibrary>::@extension::0
      firstFragment: <testLibraryFragment>::@extension::0
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@extension::0::@field::foo
          type: int
          getter: <testLibraryFragment>::@extension::0::@getter::foo#element
      getters
        get foo
          firstFragment: <testLibraryFragment>::@extension::0::@getter::foo
          returnType: int
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      typeAliases
        F @34
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        hasInitializer V2 @56
          reference: <testLibraryFragment>::@topLevelVariable::V2
          element: <testLibrary>::@topLevelVariable::V2
          getter2: <testLibraryFragment>::@getter::V2
          setter2: <testLibraryFragment>::@setter::V2
        hasInitializer V @71
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          getter2: <testLibraryFragment>::@getter::V
          setter2: <testLibraryFragment>::@setter::V
      getters
        synthetic get V2
          reference: <testLibraryFragment>::@getter::V2
          element: <testLibraryFragment>::@getter::V2#element
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
      setters
        synthetic set V2
          reference: <testLibraryFragment>::@setter::V2
          element: <testLibraryFragment>::@setter::V2#element
          formalParameters
            _V2
              element: <testLibraryFragment>::@setter::V2::@parameter::_V2#element
        synthetic set V
          reference: <testLibraryFragment>::@setter::V
          element: <testLibraryFragment>::@setter::V#element
          formalParameters
            _V
              element: <testLibraryFragment>::@setter::V::@parameter::_V#element
      functions
        f @44
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            p @48
              element: <testLibraryFragment>::@function::f::@parameter::p#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: dynamic
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: dynamic Function(dynamic)
  topLevelVariables
    hasInitializer V2
      reference: <testLibrary>::@topLevelVariable::V2
      firstFragment: <testLibraryFragment>::@topLevelVariable::V2
      type: dynamic
      getter: <testLibraryFragment>::@getter::V2#element
      setter: <testLibraryFragment>::@setter::V2#element
    hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: int
      getter: <testLibraryFragment>::@getter::V#element
      setter: <testLibraryFragment>::@setter::V#element
  getters
    synthetic static get V2
      firstFragment: <testLibraryFragment>::@getter::V2
      returnType: dynamic
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: int
  setters
    synthetic static set V2
      firstFragment: <testLibraryFragment>::@setter::V2
      formalParameters
        requiredPositional _V2
          type: dynamic
      returnType: void
    synthetic static set V
      firstFragment: <testLibraryFragment>::@setter::V
      formalParameters
        requiredPositional _V
          type: int
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional p
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        V @4
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          getter2: <testLibraryFragment>::@getter::V
          setter2: <testLibraryFragment>::@setter::V
        V2 @22
          reference: <testLibraryFragment>::@topLevelVariable::V2
          element: <testLibrary>::@topLevelVariable::V2
          getter2: <testLibraryFragment>::@getter::V2
          setter2: <testLibraryFragment>::@setter::V2
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
        synthetic get V2
          reference: <testLibraryFragment>::@getter::V2
          element: <testLibraryFragment>::@getter::V2#element
      setters
        synthetic set V
          reference: <testLibraryFragment>::@setter::V
          element: <testLibraryFragment>::@setter::V#element
          formalParameters
            _V
              element: <testLibraryFragment>::@setter::V::@parameter::_V#element
        synthetic set V2
          reference: <testLibraryFragment>::@setter::V2
          element: <testLibraryFragment>::@setter::V2#element
          formalParameters
            _V2
              element: <testLibraryFragment>::@setter::V2::@parameter::_V2#element
  topLevelVariables
    V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: dynamic
      getter: <testLibraryFragment>::@getter::V#element
      setter: <testLibraryFragment>::@setter::V#element
    V2
      reference: <testLibrary>::@topLevelVariable::V2
      firstFragment: <testLibraryFragment>::@topLevelVariable::V2
      type: List<dynamic>
      getter: <testLibraryFragment>::@getter::V2#element
      setter: <testLibraryFragment>::@setter::V2#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: dynamic
    synthetic static get V2
      firstFragment: <testLibraryFragment>::@getter::V2
      returnType: List<dynamic>
  setters
    synthetic static set V
      firstFragment: <testLibraryFragment>::@setter::V
      formalParameters
        requiredPositional _V
          type: dynamic
      returnType: void
    synthetic static set V2
      firstFragment: <testLibraryFragment>::@setter::V2
      formalParameters
        requiredPositional _V2
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            m @15
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <testLibraryFragment>::@class::C::@method::m#element
              formalParameters
                p @21
                  element: <testLibraryFragment>::@class::C::@method::m::@parameter::p#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        m
          firstFragment: <testLibraryFragment>::@class::C::@method::m
          formalParameters
            requiredPositional p
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        v @4
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        synthetic set v
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  topLevelVariables
    v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: InvalidType
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: InvalidType
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
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
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        d @6
          reference: <testLibraryFragment>::@topLevelVariable::d
          element: <testLibrary>::@topLevelVariable::d
          getter2: <testLibraryFragment>::@getter::d
          setter2: <testLibraryFragment>::@setter::d
      getters
        synthetic get d
          reference: <testLibraryFragment>::@getter::d
          element: <testLibraryFragment>::@getter::d#element
      setters
        synthetic set d
          reference: <testLibraryFragment>::@setter::d
          element: <testLibraryFragment>::@setter::d#element
          formalParameters
            _d
              element: <testLibraryFragment>::@setter::d::@parameter::_d#element
  topLevelVariables
    d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: <testLibraryFragment>::@topLevelVariable::d
      type: Never
      getter: <testLibraryFragment>::@getter::d#element
      setter: <testLibraryFragment>::@setter::d#element
  getters
    synthetic static get d
      firstFragment: <testLibraryFragment>::@getter::d
      returnType: Never
  setters
    synthetic static set d
      firstFragment: <testLibraryFragment>::@setter::d
      formalParameters
        requiredPositional _d
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
          fields
            t @17
              reference: <testLibraryFragment>::@class::C::@field::t
              element: <testLibraryFragment>::@class::C::@field::t#element
              getter2: <testLibraryFragment>::@class::C::@getter::t
              setter2: <testLibraryFragment>::@class::C::@setter::t
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get t
              reference: <testLibraryFragment>::@class::C::@getter::t
              element: <testLibraryFragment>::@class::C::@getter::t#element
          setters
            synthetic set t
              reference: <testLibraryFragment>::@class::C::@setter::t
              element: <testLibraryFragment>::@class::C::@setter::t#element
              formalParameters
                _t
                  element: <testLibraryFragment>::@class::C::@setter::t::@parameter::_t#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      fields
        t
          firstFragment: <testLibraryFragment>::@class::C::@field::t
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibraryFragment>::@class::C::@getter::t#element
          setter: <testLibraryFragment>::@class::C::@setter::t#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get t
          firstFragment: <testLibraryFragment>::@class::C::@getter::t
          hasEnclosingTypeParameterReference: true
          returnType: T
      setters
        synthetic set t
          firstFragment: <testLibraryFragment>::@class::C::@setter::t
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _t
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
          fields
            t @18
              reference: <testLibraryFragment>::@class::C::@field::t
              element: <testLibraryFragment>::@class::C::@field::t#element
              getter2: <testLibraryFragment>::@class::C::@getter::t
              setter2: <testLibraryFragment>::@class::C::@setter::t
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get t
              reference: <testLibraryFragment>::@class::C::@getter::t
              element: <testLibraryFragment>::@class::C::@getter::t#element
          setters
            synthetic set t
              reference: <testLibraryFragment>::@class::C::@setter::t
              element: <testLibraryFragment>::@class::C::@setter::t#element
              formalParameters
                _t
                  element: <testLibraryFragment>::@class::C::@setter::t::@parameter::_t#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      fields
        t
          firstFragment: <testLibraryFragment>::@class::C::@field::t
          hasEnclosingTypeParameterReference: true
          type: T?
          getter: <testLibraryFragment>::@class::C::@getter::t#element
          setter: <testLibraryFragment>::@class::C::@setter::t#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get t
          firstFragment: <testLibraryFragment>::@class::C::@getter::t
          hasEnclosingTypeParameterReference: true
          returnType: T?
      setters
        synthetic set t
          firstFragment: <testLibraryFragment>::@class::C::@setter::t
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _t
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      enums
        enum E @16
          reference: <testLibraryFragment>::@enum::E
          element: <testLibrary>::@enum::E
          fields
            hasInitializer v @20
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              typeName: E
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      typeAliases
        F @32
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        c @39
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @44
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @49
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get e
          reference: <testLibraryFragment>::@getter::e
          element: <testLibraryFragment>::@getter::e#element
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            _e
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
          returnType: E
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
          returnType: List<E>
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      type: E
      getter: <testLibraryFragment>::@getter::e#element
      setter: <testLibraryFragment>::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      parts
        part_0
          uri: package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        c @28
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @33
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @38
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get e
          reference: <testLibraryFragment>::@getter::e
          element: <testLibraryFragment>::@getter::e#element
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            _e
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      classes
        class C @17
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new#element
              typeName: C
      enums
        enum E @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          element: <testLibrary>::@enum::E
          fields
            hasInitializer v @31
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
            synthetic values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
          constructors
            synthetic const new
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new#element
              typeName: E
          getters
            synthetic get v
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
            synthetic get values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values#element
      typeAliases
        F @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::C
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
          type: E
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
            expression: expression_0
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
          type: List<E>
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
            expression: expression_1
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
          returnType: E
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
          returnType: List<E>
  typeAliases
    F
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      type: E
      getter: <testLibraryFragment>::@getter::e#element
      setter: <testLibraryFragment>::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      parts
        part_0
          uri: package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class C @32
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      enums
        enum E @42
          reference: <testLibraryFragment>::@enum::E
          element: <testLibrary>::@enum::E
          fields
            hasInitializer v @46
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              typeName: E
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      typeAliases
        F @58
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        c @13
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::c
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::c
        e @18
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::e
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::e
        f @23
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::f
      getters
        synthetic get c
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::c
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::c#element
        synthetic get e
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::e
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::e#element
        synthetic get f
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::f#element
      setters
        synthetic set c
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::c
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::c#element
          formalParameters
            _c
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::e
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::e#element
          formalParameters
            _e
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::f
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::f#element
          formalParameters
            _f
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::f::@parameter::_f#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
          returnType: E
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
          returnType: List<E>
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::c
      type: C
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::c#element
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::e
      type: E
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::e#element
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::f#element
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::f
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      parts
        part_0
          uri: package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class C @17
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new#element
              typeName: C
      enums
        enum E @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          element: <testLibrary>::@enum::E
          fields
            hasInitializer v @31
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
            synthetic values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
          constructors
            synthetic const new
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new#element
              typeName: E
          getters
            synthetic get v
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
            synthetic get values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values#element
      typeAliases
        F @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        c @13
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibrary>::@fragment::package:test/b.dart::@getter::c
          setter2: <testLibrary>::@fragment::package:test/b.dart::@setter::c
        e @18
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibrary>::@fragment::package:test/b.dart::@getter::e
          setter2: <testLibrary>::@fragment::package:test/b.dart::@setter::e
        f @23
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibrary>::@fragment::package:test/b.dart::@getter::f
          setter2: <testLibrary>::@fragment::package:test/b.dart::@setter::f
      getters
        synthetic get c
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::c
          element: <testLibrary>::@fragment::package:test/b.dart::@getter::c#element
        synthetic get e
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::e
          element: <testLibrary>::@fragment::package:test/b.dart::@getter::e#element
        synthetic get f
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::f
          element: <testLibrary>::@fragment::package:test/b.dart::@getter::f#element
      setters
        synthetic set c
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::c
          element: <testLibrary>::@fragment::package:test/b.dart::@setter::c#element
          formalParameters
            _c
              element: <testLibrary>::@fragment::package:test/b.dart::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::e
          element: <testLibrary>::@fragment::package:test/b.dart::@setter::e#element
          formalParameters
            _e
              element: <testLibrary>::@fragment::package:test/b.dart::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::f
          element: <testLibrary>::@fragment::package:test/b.dart::@setter::f#element
          formalParameters
            _f
              element: <testLibrary>::@fragment::package:test/b.dart::@setter::f::@parameter::_f#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::C
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
          type: E
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
            expression: expression_0
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
          type: List<E>
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
            expression: expression_1
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
          returnType: E
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
          returnType: List<E>
  typeAliases
    F
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::c
      type: C
      getter: <testLibrary>::@fragment::package:test/b.dart::@getter::c#element
      setter: <testLibrary>::@fragment::package:test/b.dart::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::e
      type: E
      getter: <testLibrary>::@fragment::package:test/b.dart::@getter::e#element
      setter: <testLibrary>::@fragment::package:test/b.dart::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::f
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@fragment::package:test/b.dart::@getter::f#element
      setter: <testLibrary>::@fragment::package:test/b.dart::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@getter::f
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      parts
        part_0
          uri: package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      classes
        class C @17
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new#element
              typeName: C
      enums
        enum E @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          element: <testLibrary>::@enum::E
          fields
            hasInitializer v @31
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
            synthetic values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
          constructors
            synthetic const new
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new#element
              typeName: E
          getters
            synthetic get v
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
            synthetic get values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values#element
      typeAliases
        F @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        c @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::c
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::c
        e @55
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::e
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::e
        f @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::f
      getters
        synthetic get c
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::c
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::c#element
        synthetic get e
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::e
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::e#element
        synthetic get f
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::f#element
      setters
        synthetic set c
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::c
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::c#element
          formalParameters
            _c
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::e
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::e#element
          formalParameters
            _e
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::f
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::f#element
          formalParameters
            _f
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::f::@parameter::_f#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::C
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
          type: E
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
            expression: expression_0
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
          type: List<E>
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
            expression: expression_1
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
          returnType: E
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
          returnType: List<E>
  typeAliases
    F
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::c
      type: C
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::c#element
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::e
      type: E
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::e#element
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::f#element
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::f
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      topLevelVariables
        c @13
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
            U @11
              element: U@11
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      topLevelVariables
        c @32
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
        U
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C<int, String>
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C<int, String>
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @8
              element: T@8
            U @11
              element: U@11
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      topLevelVariables
        c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
        U
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C<dynamic, dynamic>
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C<dynamic, dynamic>
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
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
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibrary>::@enum::E
          fields
            hasInitializer v @9
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              typeName: E
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      topLevelVariables
        e @15
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
      getters
        synthetic get e
          reference: <testLibraryFragment>::@getter::e
          element: <testLibraryFragment>::@getter::e#element
      setters
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            _e
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
          returnType: E
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
          returnType: List<E>
  topLevelVariables
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      type: E
      getter: <testLibraryFragment>::@getter::e#element
      setter: <testLibraryFragment>::@setter::e#element
  getters
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
      returnType: E
  setters
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get e
          reference: <testLibraryFragment>::@getter::e
          element: <testLibraryFragment>::@getter::e#element
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            _e
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      type: E
      getter: <testLibraryFragment>::@getter::e#element
      setter: <testLibraryFragment>::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get e
          reference: <testLibraryFragment>::@getter::e
          element: <testLibraryFragment>::@getter::e#element
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            _e
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      type: E
      getter: <testLibraryFragment>::@getter::e#element
      setter: <testLibraryFragment>::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function()
        alias: package:test/b.dart::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function()
        alias: package:test/b.dart::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get e
          reference: <testLibraryFragment>::@getter::e
          element: <testLibraryFragment>::@getter::e#element
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            _e
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      type: E
      getter: <testLibraryFragment>::@getter::e#element
      setter: <testLibraryFragment>::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function()
        alias: package:test/c.dart::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function()
        alias: package:test/c.dart::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a/a.dart
      topLevelVariables
        c @21
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @26
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @31
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get e
          reference: <testLibraryFragment>::@getter::e
          element: <testLibraryFragment>::@getter::e#element
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            _e
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      type: E
      getter: <testLibraryFragment>::@getter::e#element
      setter: <testLibraryFragment>::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function()
        alias: package:test/a/c/c.dart::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function()
        alias: package:test/a/c/c.dart::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a/a.dart
      topLevelVariables
        c @21
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @26
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @31
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get e
          reference: <testLibraryFragment>::@getter::e
          element: <testLibraryFragment>::@getter::e#element
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            _e
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      type: E
      getter: <testLibraryFragment>::@getter::e#element
      setter: <testLibraryFragment>::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function()
        alias: package:test/a/b/b.dart::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function()
        alias: package:test/a/b/b.dart::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get e
          reference: <testLibraryFragment>::@getter::e
          element: <testLibraryFragment>::@getter::e#element
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            _e
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      type: E
      getter: <testLibraryFragment>::@getter::e#element
      setter: <testLibraryFragment>::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        c1 @20
          reference: <testLibraryFragment>::@topLevelVariable::c1
          element: <testLibrary>::@topLevelVariable::c1
          getter2: <testLibraryFragment>::@getter::c1
          setter2: <testLibraryFragment>::@setter::c1
        c2 @27
          reference: <testLibraryFragment>::@topLevelVariable::c2
          element: <testLibrary>::@topLevelVariable::c2
          getter2: <testLibraryFragment>::@getter::c2
          setter2: <testLibraryFragment>::@setter::c2
      getters
        synthetic get c1
          reference: <testLibraryFragment>::@getter::c1
          element: <testLibraryFragment>::@getter::c1#element
        synthetic get c2
          reference: <testLibraryFragment>::@getter::c2
          element: <testLibraryFragment>::@getter::c2#element
      setters
        synthetic set c1
          reference: <testLibraryFragment>::@setter::c1
          element: <testLibraryFragment>::@setter::c1#element
          formalParameters
            _c1
              element: <testLibraryFragment>::@setter::c1::@parameter::_c1#element
        synthetic set c2
          reference: <testLibraryFragment>::@setter::c2
          element: <testLibraryFragment>::@setter::c2#element
          formalParameters
            _c2
              element: <testLibraryFragment>::@setter::c2::@parameter::_c2#element
  topLevelVariables
    c1
      reference: <testLibrary>::@topLevelVariable::c1
      firstFragment: <testLibraryFragment>::@topLevelVariable::c1
      type: C1
      getter: <testLibraryFragment>::@getter::c1#element
      setter: <testLibraryFragment>::@setter::c1#element
    c2
      reference: <testLibrary>::@topLevelVariable::c2
      firstFragment: <testLibraryFragment>::@topLevelVariable::c2
      type: C2
      getter: <testLibraryFragment>::@getter::c2#element
      setter: <testLibraryFragment>::@setter::c2#element
  getters
    synthetic static get c1
      firstFragment: <testLibraryFragment>::@getter::c1
      returnType: C1
    synthetic static get c2
      firstFragment: <testLibraryFragment>::@getter::c2
      returnType: C2
  setters
    synthetic static set c1
      firstFragment: <testLibraryFragment>::@setter::c1
      formalParameters
        requiredPositional _c1
          type: C1
      returnType: void
    synthetic static set c2
      firstFragment: <testLibraryFragment>::@setter::c2
      formalParameters
        requiredPositional _c2
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a/b.dart
      topLevelVariables
        c @21
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @26
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @31
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get e
          reference: <testLibraryFragment>::@getter::e
          element: <testLibraryFragment>::@getter::e#element
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            _e
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      type: E
      getter: <testLibraryFragment>::@getter::e#element
      setter: <testLibraryFragment>::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function()
        alias: package:test/a/b.dart::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function()
        alias: package:test/a/b.dart::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <testLibrary>::@topLevelVariable::e
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get e
          reference: <testLibraryFragment>::@getter::e
          element: <testLibraryFragment>::@getter::e#element
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            _e
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      type: E
      getter: <testLibraryFragment>::@getter::e#element
      setter: <testLibraryFragment>::@setter::e#element
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
      returnType: E
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
      returnType: void
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        f @15
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: dynamic Function()
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @10
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
          typeParameters
            T @12
              element: T@12
            U @15
              element: U@15
      topLevelVariables
        f @39
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      typeParameters
        T
        U
      aliasedType: U Function(T)
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: String Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
            String
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: String Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
            String
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @10
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
          typeParameters
            T @12
              element: T@12
            U @15
              element: U@15
      topLevelVariables
        f @26
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      typeParameters
        T
        U
      aliasedType: U Function(T)
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function(dynamic)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            dynamic
            dynamic
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function(dynamic)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            dynamic
            dynamic
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
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
