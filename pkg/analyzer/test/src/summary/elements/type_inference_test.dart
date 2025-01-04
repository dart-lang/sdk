// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/context_collection_resolution.dart';
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static final f @6
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: V Function<U, V>(U, V)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: V Function<U, V>(U, V)
----------------------------------------
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
''');
  }

  test_closure_in_variable_declaration_in_part() async {
    newFile('$testPackageLibPath/a.dart',
        'part of lib; final f = (int i) => i.toDouble();');
    var library = await buildLibrary('''
library lib;
part "a.dart";
''');
    checkElementText(library, r'''
library
  name: lib
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static final f @19
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: double Function(int)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get f @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: double Function(int)
----------------------------------------
library
  reference: <testLibrary>
  name: lib
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            final f @21
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement3: <testLibraryFragment>::@class::C
              type: InvalidType
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: InvalidType
----------------------------------------
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
              element: <not-implemented>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @43
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant V @45
              defaultType: dynamic
          constructors
            const @58
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional f @65
                  type: D<V, U> Function<U>()
                    alias: <testLibraryFragment>::@typeAlias::F
                      typeArguments
                        V
        class D @77
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @79
              defaultType: dynamic
            covariant U @81
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: D<T, U> Function<U>()
          aliasedElement: GenericFunctionTypeElement
            typeParameters
              covariant U @31
            returnType: D<T, U>
      topLevelVariables
        static const x @118
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: C<int>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @122
              constructorName: ConstructorName
                type: NamedType
                  name: C @128
                  element: <testLibraryFragment>::@class::C
                  element2: <testLibrary>::@class::C
                  type: C<int>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::new
                  substitution: {V: int}
                element: <testLibraryFragment>::@class::C::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @129
                arguments
                  SimpleIdentifier
                    token: f @130
                    staticElement: <testLibraryFragment>::@function::f
                    element: <testLibrary>::@function::f
                    staticType: D<int, U> Function<U>()
                rightParenthesis: ) @131
              staticType: C<int>
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: C<int>
      functions
        f @96
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant U @98
              defaultType: dynamic
          returnType: D<int, U>
----------------------------------------
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
              element: <not-implemented>
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
              element: <not-implemented>
            U @81
              element: <not-implemented>
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
              element: <not-implemented>
      topLevelVariables
        hasInitializer x @118
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
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
              element: <not-implemented>
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
                alias: <testLibraryFragment>::@typeAlias::F
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
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @38
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            const @50
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional f @54
                  type: D<T> Function<T>()
                    alias: <testLibraryFragment>::@typeAlias::F
        class D @66
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @68
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: D<T> Function<T>()
          aliasedElement: GenericFunctionTypeElement
            typeParameters
              covariant T @26
            returnType: D<T>
      topLevelVariables
        static const x @101
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @105
              constructorName: ConstructorName
                type: NamedType
                  name: C @111
                  element: <testLibraryFragment>::@class::C
                  element2: <testLibrary>::@class::C
                  type: C
                staticElement: <testLibraryFragment>::@class::C::@constructor::new
                element: <testLibraryFragment>::@class::C::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @112
                arguments
                  SimpleIdentifier
                    token: f @113
                    staticElement: <testLibraryFragment>::@function::f
                    element: <testLibrary>::@function::f
                    staticType: D<T> Function<T>()
                rightParenthesis: ) @114
              staticType: C
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: C
      functions
        f @79
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @81
              defaultType: dynamic
          returnType: D<T>
----------------------------------------
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
              element: <not-implemented>
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
              element: <not-implemented>
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
                alias: <testLibraryFragment>::@typeAlias::F
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
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
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
        class B @18
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class S @40
          reference: <testLibraryFragment>::@class::S
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @42
              bound: A
              defaultType: A
          constructors
            @59
              reference: <testLibraryFragment>::@class::S::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::S
              parameters
                requiredPositional _ @63
                  type: T
      topLevelVariables
        static s @74
          reference: <testLibraryFragment>::@topLevelVariable::s
          enclosingElement3: <testLibraryFragment>
          type: S<B>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get s @-1
          reference: <testLibraryFragment>::@getter::s
          enclosingElement3: <testLibraryFragment>
          returnType: S<B>
        synthetic static set s= @-1
          reference: <testLibraryFragment>::@setter::s
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _s @-1
              type: S<B>
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
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class S @40
          reference: <testLibraryFragment>::@class::S
          element: <testLibrary>::@class::S
          typeParameters
            T @42
              element: <not-implemented>
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
            <null-name>
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
  setters
    synthetic static set s
      firstFragment: <testLibraryFragment>::@setter::s
      formalParameters
        requiredPositional _s
          type: S<B>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            b @14
              reference: <testLibraryFragment>::@class::A::@field::b
              enclosingElement3: <testLibraryFragment>::@class::A
              type: B
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            synthetic get b @-1
              reference: <testLibraryFragment>::@class::A::@getter::b
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: B
            synthetic set b= @-1
              reference: <testLibraryFragment>::@class::A::@setter::b
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _b @-1
                  type: B
              returnType: void
        class B @25
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          fields
            synthetic c @-1
              reference: <testLibraryFragment>::@class::B::@field::c
              enclosingElement3: <testLibraryFragment>::@class::B
              type: C
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
          accessors
            get c @37
              reference: <testLibraryFragment>::@class::B::@getter::c
              enclosingElement3: <testLibraryFragment>::@class::B
              returnType: C
            set c= @59
              reference: <testLibraryFragment>::@class::B::@setter::c
              enclosingElement3: <testLibraryFragment>::@class::B
              parameters
                requiredPositional value @63
                  type: C
              returnType: void
        class C @81
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
        class D @92
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          supertype: C
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
              superConstructor: <testLibraryFragment>::@class::C::@constructor::new
      topLevelVariables
        static a @111
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: A
          shouldUseTypeForInitializerInference: false
        static x @128
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: A
        synthetic static set a= @-1
          reference: <testLibraryFragment>::@setter::a
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _a @-1
              type: A
          returnType: void
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: C
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
                <null-name>
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
              superConstructor: <testLibraryFragment>::@class::C::@constructor::new
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
            <null-name>
              element: <testLibraryFragment>::@setter::a::@parameter::_a#element
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            <null-name>
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
      setters
        synthetic set b
          firstFragment: <testLibraryFragment>::@class::A::@setter::b
          formalParameters
            requiredPositional _b
              type: B
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
      setters
        set c
          firstFragment: <testLibraryFragment>::@class::B::@setter::c
          formalParameters
            requiredPositional value
              type: C
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
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set a
      firstFragment: <testLibraryFragment>::@setter::a
      formalParameters
        requiredPositional _a
          type: A
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Iterable<String>
          shouldUseTypeForInitializerInference: false
        static y @40
          reference: <testLibraryFragment>::@topLevelVariable::y
          enclosingElement3: <testLibraryFragment>
          type: List<int>
          shouldUseTypeForInitializerInference: false
        static z @53
          reference: <testLibraryFragment>::@topLevelVariable::z
          enclosingElement3: <testLibraryFragment>
          type: List<String>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Iterable<String>
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: Iterable<String>
          returnType: void
        synthetic static get y @-1
          reference: <testLibraryFragment>::@getter::y
          enclosingElement3: <testLibraryFragment>
          returnType: List<int>
        synthetic static set y= @-1
          reference: <testLibraryFragment>::@setter::y
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _y @-1
              type: List<int>
          returnType: void
        synthetic static get z @-1
          reference: <testLibraryFragment>::@getter::z
          enclosingElement3: <testLibraryFragment>
          returnType: List<String>
        synthetic static set z= @-1
          reference: <testLibraryFragment>::@setter::z
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _z @-1
              type: List<String>
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
        synthetic set y
          reference: <testLibraryFragment>::@setter::y
          element: <testLibraryFragment>::@setter::y#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::y::@parameter::_y#element
        synthetic set z
          reference: <testLibraryFragment>::@setter::z
          element: <testLibraryFragment>::@setter::z#element
          formalParameters
            <null-name>
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
    synthetic static get y
      firstFragment: <testLibraryFragment>::@getter::y
    synthetic static get z
      firstFragment: <testLibraryFragment>::@getter::z
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: Iterable<String>
    synthetic static set y
      firstFragment: <testLibraryFragment>::@setter::y
      formalParameters
        requiredPositional _y
          type: List<int>
    synthetic static set z
      firstFragment: <testLibraryFragment>::@setter::z
      formalParameters
        requiredPositional _z
          type: List<String>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            p @16
              reference: <testLibraryFragment>::@class::C::@field::p
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get p @-1
              reference: <testLibraryFragment>::@class::C::@getter::p
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set p= @-1
              reference: <testLibraryFragment>::@class::C::@setter::p
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _p @-1
                  type: int
              returnType: void
      topLevelVariables
        static x @25
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: List<C>
          shouldUseTypeForInitializerInference: false
        static y @40
          reference: <testLibraryFragment>::@topLevelVariable::y
          enclosingElement3: <testLibraryFragment>
          type: Iterable<int>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: List<C>
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: List<C>
          returnType: void
        synthetic static get y @-1
          reference: <testLibraryFragment>::@getter::y
          enclosingElement3: <testLibraryFragment>
          returnType: Iterable<int>
        synthetic static set y= @-1
          reference: <testLibraryFragment>::@setter::y
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _y @-1
              type: Iterable<int>
          returnType: void
----------------------------------------
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
                <null-name>
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
            <null-name>
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
        synthetic set y
          reference: <testLibraryFragment>::@setter::y
          element: <testLibraryFragment>::@setter::y#element
          formalParameters
            <null-name>
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
      setters
        synthetic set p
          firstFragment: <testLibraryFragment>::@class::C::@setter::p
          formalParameters
            requiredPositional _p
              type: int
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
    synthetic static get y
      firstFragment: <testLibraryFragment>::@getter::y
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: List<C>
    synthetic static set y
      firstFragment: <testLibraryFragment>::@setter::y
      formalParameters
        requiredPositional _y
          type: Iterable<int>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant U @2
              defaultType: dynamic
            covariant V @5
              defaultType: dynamic
          returnType: dynamic
----------------------------------------
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
              element: <not-implemented>
            V @5
              element: <not-implemented>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant U @8
              defaultType: dynamic
            covariant V @11
              defaultType: dynamic
          fields
            final x @24
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic
----------------------------------------
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
              element: <not-implemented>
            V @11
              element: <not-implemented>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant U @8
              defaultType: dynamic
            covariant V @11
              defaultType: dynamic
          fields
            synthetic x @-1
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            get x @22
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic
----------------------------------------
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
              element: <not-implemented>
            V @11
              element: <not-implemented>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            f @15
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement3: <testLibraryFragment>::@class::C
              typeParameters
                covariant U @17
                  defaultType: dynamic
                covariant V @20
                  defaultType: dynamic
              returnType: dynamic
----------------------------------------
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
              element: <not-implemented>
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
                  element: <not-implemented>
                V @20
                  element: <not-implemented>
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
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          typeParameters
            U
            V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant U @8
              defaultType: dynamic
            covariant V @11
              defaultType: dynamic
          fields
            synthetic x @-1
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            set x= @27
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional hasImplicitType value @29
                  type: dynamic
              returnType: void
----------------------------------------
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
              element: <not-implemented>
            V @11
              element: <not-implemented>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @2
              defaultType: dynamic
          returnType: dynamic
----------------------------------------
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
              element: <not-implemented>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @2
              defaultType: dynamic
          returnType: dynamic
----------------------------------------
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
              element: <not-implemented>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant P @8
              bound: num
              defaultType: num
          constructors
            factory @35
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional p @49
                  type: Iterable<P>
            _ @66
              reference: <testLibraryFragment>::@class::C::@constructor::_
              enclosingElement3: <testLibraryFragment>::@class::C
              periodOffset: 65
              nameEnd: 67
      topLevelVariables
        static c @78
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C<num>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C<num>
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C<num>
          returnType: void
----------------------------------------
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
              element: <not-implemented>
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
            <null-name>
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
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C<num>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            static final foo @25
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
              shouldUseTypeForInitializerInference: false
            static final bar @56
              reference: <testLibraryFragment>::@class::A::@field::bar
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int Function(double)
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
            synthetic static get bar @-1
              reference: <testLibraryFragment>::@class::A::@getter::bar
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int Function(double)
          methods
            static baz @100
              reference: <testLibraryFragment>::@class::A::@method::baz
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int Function(double)
----------------------------------------
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
        synthetic static get bar
          firstFragment: <testLibraryFragment>::@class::A::@getter::bar
      methods
        static baz
          reference: <testLibrary>::@class::A::@method::baz
          firstFragment: <testLibraryFragment>::@class::A::@method::baz
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: int
          returnType: void
      functions
        m @4
          reference: <testLibraryFragment>::@function::m
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @6
              defaultType: dynamic
          returnType: int
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
      functions
        m @4
          reference: <testLibraryFragment>::@function::m
          element: <testLibrary>::@function::m
          typeParameters
            T @6
              element: <not-implemented>
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
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static m @19
          reference: <testLibraryFragment>::@topLevelVariable::m
          enclosingElement3: <testLibraryFragment>
          type: int Function<T>()?
          shouldUseTypeForInitializerInference: true
        static n @53
          reference: <testLibraryFragment>::@topLevelVariable::n
          enclosingElement3: <testLibraryFragment>
          type: int Function<T>()
          shouldUseTypeForInitializerInference: true
        static x @73
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get m @-1
          reference: <testLibraryFragment>::@getter::m
          enclosingElement3: <testLibraryFragment>
          returnType: int Function<T>()?
        synthetic static set m= @-1
          reference: <testLibraryFragment>::@setter::m
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _m @-1
              type: int Function<T>()?
          returnType: void
        synthetic static get n @-1
          reference: <testLibraryFragment>::@getter::n
          enclosingElement3: <testLibraryFragment>
          returnType: int Function<T>()
        synthetic static set n= @-1
          reference: <testLibraryFragment>::@setter::n
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _n @-1
              type: int Function<T>()
          returnType: void
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: int
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::m::@parameter::_m#element
        synthetic set n
          reference: <testLibraryFragment>::@setter::n
          element: <testLibraryFragment>::@setter::n#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::n::@parameter::_n#element
        synthetic set x
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            <null-name>
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
    synthetic static get n
      firstFragment: <testLibraryFragment>::@getter::n
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set m
      firstFragment: <testLibraryFragment>::@setter::m
      formalParameters
        requiredPositional _m
          type: int Function<T>()?
    synthetic static set n
      firstFragment: <testLibraryFragment>::@setter::n
      formalParameters
        requiredPositional _n
          type: int Function<T>()
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:collection
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static m @30
          reference: <testLibraryFragment>::@topLevelVariable::m
          enclosingElement3: <testLibraryFragment>
          type: HashMap<dynamic, dynamic>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get m @-1
          reference: <testLibraryFragment>::@getter::m
          enclosingElement3: <testLibraryFragment>
          returnType: HashMap<dynamic, dynamic>
        synthetic static set m= @-1
          reference: <testLibraryFragment>::@setter::m
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _m @-1
              type: HashMap<dynamic, dynamic>
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set m
      firstFragment: <testLibraryFragment>::@setter::m
      formalParameters
        requiredPositional _m
          type: HashMap<dynamic, dynamic>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static c @34
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static d @49
          reference: <testLibraryFragment>::@topLevelVariable::d
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static set a= @-1
          reference: <testLibraryFragment>::@setter::a
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _a @-1
              type: dynamic
          returnType: void
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static set b= @-1
          reference: <testLibraryFragment>::@setter::b
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _b @-1
              type: dynamic
          returnType: void
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: dynamic
          returnType: void
        synthetic static get d @-1
          reference: <testLibraryFragment>::@getter::d
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set d= @-1
          reference: <testLibraryFragment>::@setter::d
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _d @-1
              type: int
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::a::@parameter::_a#element
        synthetic set b
          reference: <testLibraryFragment>::@setter::b
          element: <testLibraryFragment>::@setter::b#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::b::@parameter::_b#element
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set d
          reference: <testLibraryFragment>::@setter::d
          element: <testLibraryFragment>::@setter::d#element
          formalParameters
            <null-name>
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
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get d
      firstFragment: <testLibraryFragment>::@getter::d
  setters
    synthetic static set a
      firstFragment: <testLibraryFragment>::@setter::a
      formalParameters
        requiredPositional _a
          type: dynamic
    synthetic static set b
      firstFragment: <testLibraryFragment>::@setter::b
      formalParameters
        requiredPositional _b
          type: dynamic
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: dynamic
    synthetic static set d
      firstFragment: <testLibraryFragment>::@setter::d
      formalParameters
        requiredPositional _d
          type: int
''');
  }

  test_inferred_type_is_typedef() async {
    var library = await buildLibrary('typedef int F(String s);'
        ' class C extends D { var v; }'
        ' abstract class D { F get v; }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @31
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          supertype: D
          fields
            v @49
              reference: <testLibraryFragment>::@class::C::@field::v
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int Function(String)
                alias: <testLibraryFragment>::@typeAlias::F
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          accessors
            synthetic get v @-1
              reference: <testLibraryFragment>::@class::C::@getter::v
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int Function(String)
                alias: <testLibraryFragment>::@typeAlias::F
            synthetic set v= @-1
              reference: <testLibraryFragment>::@class::C::@setter::v
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _v @-1
                  type: int Function(String)
                    alias: <testLibraryFragment>::@typeAlias::F
              returnType: void
        abstract class D @69
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          fields
            synthetic v @-1
              reference: <testLibraryFragment>::@class::D::@field::v
              enclosingElement3: <testLibraryFragment>::@class::D
              type: int Function(String)
                alias: <testLibraryFragment>::@typeAlias::F
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
          accessors
            abstract get v @79
              reference: <testLibraryFragment>::@class::D::@getter::v
              enclosingElement3: <testLibraryFragment>::@class::D
              returnType: int Function(String)
                alias: <testLibraryFragment>::@typeAlias::F
      typeAliases
        functionTypeAliasBased F @12
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: int Function(String)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional s @21
                type: String
            returnType: int
----------------------------------------
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
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          getters
            synthetic get v
              reference: <testLibraryFragment>::@class::C::@getter::v
              element: <testLibraryFragment>::@class::C::@getter::v#element
          setters
            synthetic set v
              reference: <testLibraryFragment>::@class::C::@setter::v
              element: <testLibraryFragment>::@class::C::@setter::v#element
              formalParameters
                <null-name>
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
            alias: <testLibraryFragment>::@typeAlias::F
          getter: <testLibraryFragment>::@class::C::@getter::v#element
          setter: <testLibraryFragment>::@class::C::@setter::v#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::D::@constructor::new#element
      getters
        synthetic get v
          firstFragment: <testLibraryFragment>::@class::C::@getter::v
      setters
        synthetic set v
          firstFragment: <testLibraryFragment>::@class::C::@setter::v
          formalParameters
            requiredPositional _v
              type: int Function(String)
                alias: <testLibraryFragment>::@typeAlias::F
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      fields
        synthetic v
          firstFragment: <testLibraryFragment>::@class::D::@field::v
          type: int Function(String)
            alias: <testLibraryFragment>::@typeAlias::F
          getter: <testLibraryFragment>::@class::D::@getter::v#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      getters
        abstract get v
          firstFragment: <testLibraryFragment>::@class::D::@getter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: int
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int?
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int?
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: int?
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int?
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: void Function()
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: void Function()
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: void Function()
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: void Function()
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: void Function()?
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: void Function()?
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: void Function()?
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: void Function()?
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          supertype: D<int, T>
          fields
            v @37
              reference: <testLibraryFragment>::@class::C::@field::v
              enclosingElement3: <testLibraryFragment>::@class::C
              type: Map<T, int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::D::@constructor::new
                substitution: {U: int, V: T}
          accessors
            synthetic get v @-1
              reference: <testLibraryFragment>::@class::C::@getter::v
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: Map<T, int>
            synthetic set v= @-1
              reference: <testLibraryFragment>::@class::C::@setter::v
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _v @-1
                  type: Map<T, int>
              returnType: void
        abstract class D @57
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant U @59
              defaultType: dynamic
            covariant V @62
              defaultType: dynamic
          fields
            synthetic v @-1
              reference: <testLibraryFragment>::@class::D::@field::v
              enclosingElement3: <testLibraryFragment>::@class::D
              type: Map<V, U>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
          accessors
            abstract get v @83
              reference: <testLibraryFragment>::@class::D::@getter::v
              enclosingElement3: <testLibraryFragment>::@class::D
              returnType: Map<V, U>
----------------------------------------
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
              element: <not-implemented>
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
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::D::@constructor::new
                substitution: {U: int, V: T}
          getters
            synthetic get v
              reference: <testLibraryFragment>::@class::C::@getter::v
              element: <testLibraryFragment>::@class::C::@getter::v#element
          setters
            synthetic set v
              reference: <testLibraryFragment>::@class::C::@setter::v
              element: <testLibraryFragment>::@class::C::@setter::v#element
              formalParameters
                <null-name>
                  element: <testLibraryFragment>::@class::C::@setter::v::@parameter::_v#element
        class D @57
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          typeParameters
            U @59
              element: <not-implemented>
            V @62
              element: <not-implemented>
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
      setters
        synthetic set v
          firstFragment: <testLibraryFragment>::@class::C::@setter::v
          formalParameters
            requiredPositional _v
              type: Map<T, int>
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      typeParameters
        U
        V
      fields
        synthetic v
          firstFragment: <testLibraryFragment>::@class::D::@field::v
          type: Map<V, U>
          getter: <testLibraryFragment>::@class::D::@getter::v#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      getters
        abstract get v
          firstFragment: <testLibraryFragment>::@class::D::@getter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      typeAliases
        functionTypeAliasBased F @13
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function(int Function(String))
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional g @19
                type: int Function(String)
                parameters
                  requiredPositional s @28
                    type: String
            returnType: void
      topLevelVariables
        static v @53
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: dynamic
          returnType: void
      functions
        h @33
          reference: <testLibraryFragment>::@function::h
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional f @37
              type: void Function(int Function(String))
                alias: <testLibraryFragment>::@typeAlias::F
          returnType: dynamic
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: dynamic
  functions
    h
      reference: <testLibrary>::@function::h
      firstFragment: <testLibraryFragment>::@function::h
      formalParameters
        requiredPositional f
          type: void Function(int Function(String))
            alias: <testLibraryFragment>::@typeAlias::F
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
            covariant U @11
              defaultType: dynamic
          supertype: D<U, int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::D::@constructor::new
                substitution: {V: U, W: int}
          methods
            f @41
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional x @47
                  type: int
                requiredPositional hasImplicitType g @50
                  type: int Function(U)
              returnType: void
        abstract class D @73
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant V @75
              defaultType: dynamic
            covariant W @78
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
          methods
            abstract f @90
              reference: <testLibraryFragment>::@class::D::@method::f
              enclosingElement3: <testLibraryFragment>::@class::D
              parameters
                requiredPositional x @96
                  type: int
                requiredPositional g @101
                  type: W Function(V)
                  parameters
                    requiredPositional s @105
                      type: V
              returnType: void
----------------------------------------
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
              element: <not-implemented>
            U @11
              element: <not-implemented>
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::D::@constructor::new
                substitution: {V: U, W: int}
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
              element: <not-implemented>
            W @78
              element: <not-implemented>
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
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          formalParameters
            requiredPositional x
              type: int
            requiredPositional hasImplicitType g
              type: int Function(U)
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
          reference: <testLibrary>::@class::D::@method::f
          firstFragment: <testLibraryFragment>::@class::D::@method::f
          formalParameters
            requiredPositional x
              type: int
            requiredPositional g
              type: W Function(V)
              formalParameters
                requiredPositional s
                  type: V
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class C @23
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          supertype: D
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              superConstructor: package:test/a.dart::<fragment>::@class::D::@constructor::new
          methods
            f @44
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional x @50
                  type: int
                requiredPositional hasImplicitType g @53
                  type: int Function(String)
              returnType: void
----------------------------------------
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
              superConstructor: package:test/a.dart::<fragment>::@class::D::@constructor::new
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
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          formalParameters
            requiredPositional x
              type: int
            requiredPositional hasImplicitType g
              type: int Function(String)
''');
  }

  test_inferred_type_refers_to_method_function_typed_parameter_type() async {
    var library = await buildLibrary('class C extends D { void f(int x, g) {} }'
        ' abstract class D { void f(int x, int g(String s)); }');
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
          supertype: D
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          methods
            f @25
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional x @31
                  type: int
                requiredPositional hasImplicitType g @34
                  type: int Function(String)
              returnType: void
        abstract class D @57
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
          methods
            abstract f @66
              reference: <testLibraryFragment>::@class::D::@method::f
              enclosingElement3: <testLibraryFragment>::@class::D
              parameters
                requiredPositional x @72
                  type: int
                requiredPositional g @79
                  type: int Function(String)
                  parameters
                    requiredPositional s @88
                      type: String
              returnType: void
----------------------------------------
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
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
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
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          formalParameters
            requiredPositional x
              type: int
            requiredPositional hasImplicitType g
              type: int Function(String)
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      methods
        abstract f
          reference: <testLibrary>::@class::D::@method::f
          firstFragment: <testLibraryFragment>::@class::D::@method::f
          formalParameters
            requiredPositional x
              type: int
            requiredPositional g
              type: int Function(String)
              formalParameters
                requiredPositional s
                  type: String
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static v @40
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: dynamic
          returnType: void
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional g @7
              type: void Function(int, void Function())
              parameters
                requiredPositional x @13
                  type: int
                requiredPositional h @21
                  type: void Function()
          returnType: dynamic
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: dynamic
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static v @42
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: dynamic
          returnType: void
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalNamed default g @8
              reference: <testLibraryFragment>::@function::f::@parameter::g
              type: void Function(int, void Function())
              parameters
                requiredPositional x @14
                  type: int
                requiredPositional h @22
                  type: void Function()
          returnType: dynamic
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: dynamic
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
    var library = await buildLibrary('class C extends D { void set f(g) {} }'
        ' abstract class D { void set f(int g(String s)); }');
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
          supertype: D
          fields
            synthetic f @-1
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int Function(String)
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          accessors
            set f= @29
              reference: <testLibraryFragment>::@class::C::@setter::f
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional hasImplicitType g @31
                  type: int Function(String)
              returnType: void
        abstract class D @54
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          fields
            synthetic f @-1
              reference: <testLibraryFragment>::@class::D::@field::f
              enclosingElement3: <testLibraryFragment>::@class::D
              type: int Function(String)
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
          accessors
            abstract set f= @67
              reference: <testLibraryFragment>::@class::D::@setter::f
              enclosingElement3: <testLibraryFragment>::@class::D
              parameters
                requiredPositional g @73
                  type: int Function(String)
                  parameters
                    requiredPositional s @82
                      type: String
              returnType: void
----------------------------------------
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
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class B @23
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
              superConstructor: package:test/a.dart::<fragment>::@class::A::@constructor::new
          methods
            m @39
              reference: <testLibraryFragment>::@class::B::@method::m
              enclosingElement3: <testLibraryFragment>::@class::B
              parameters
                requiredPositional hasImplicitType p @41
                  type: Stream<dynamic>
              returnType: dynamic
----------------------------------------
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
              superConstructor: package:test/a.dart::<fragment>::@class::A::@constructor::new
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
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: <testLibraryFragment>::@class::B::@method::m
          formalParameters
            requiredPositional hasImplicitType p
              type: Stream<dynamic>
''');
    ClassElement b = library.definingCompilationUnit.classes[0];
    ParameterElement p = b.methods[0].parameters[0];
    // This test should verify that we correctly record inferred types,
    // when the type is defined in a part of an SDK library. So, test that
    // the type is actually in a part.
    var streamElement = (p.type as InterfaceType).element;
    expect(streamElement.source, isNot(streamElement.library.source));
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            @12
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
            named @21
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::A
              periodOffset: 20
              nameEnd: 26
      topLevelVariables
        static a1 @36
          reference: <testLibraryFragment>::@topLevelVariable::a1
          enclosingElement3: <testLibraryFragment>
          type: A
          shouldUseTypeForInitializerInference: false
        static a2 @50
          reference: <testLibraryFragment>::@topLevelVariable::a2
          enclosingElement3: <testLibraryFragment>
          type: A
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a1 @-1
          reference: <testLibraryFragment>::@getter::a1
          enclosingElement3: <testLibraryFragment>
          returnType: A
        synthetic static set a1= @-1
          reference: <testLibraryFragment>::@setter::a1
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _a1 @-1
              type: A
          returnType: void
        synthetic static get a2 @-1
          reference: <testLibraryFragment>::@getter::a2
          enclosingElement3: <testLibraryFragment>
          returnType: A
        synthetic static set a2= @-1
          reference: <testLibraryFragment>::@setter::a2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _a2 @-1
              type: A
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
            <null-name>
              element: <testLibraryFragment>::@setter::a1::@parameter::_a1#element
        synthetic set a2
          reference: <testLibraryFragment>::@setter::a2
          element: <testLibraryFragment>::@setter::a2#element
          formalParameters
            <null-name>
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
    synthetic static get a2
      firstFragment: <testLibraryFragment>::@getter::a2
  setters
    synthetic static set a1
      firstFragment: <testLibraryFragment>::@setter::a1
      formalParameters
        requiredPositional _a1
          type: A
    synthetic static set a2
      firstFragment: <testLibraryFragment>::@setter::a2
      formalParameters
        requiredPositional _a2
          type: A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static a1 @30
          reference: <testLibraryFragment>::@topLevelVariable::a1
          enclosingElement3: <testLibraryFragment>
          type: A
          shouldUseTypeForInitializerInference: false
        static a2 @48
          reference: <testLibraryFragment>::@topLevelVariable::a2
          enclosingElement3: <testLibraryFragment>
          type: A
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a1 @-1
          reference: <testLibraryFragment>::@getter::a1
          enclosingElement3: <testLibraryFragment>
          returnType: A
        synthetic static set a1= @-1
          reference: <testLibraryFragment>::@setter::a1
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _a1 @-1
              type: A
          returnType: void
        synthetic static get a2 @-1
          reference: <testLibraryFragment>::@getter::a2
          enclosingElement3: <testLibraryFragment>
          returnType: A
        synthetic static set a2= @-1
          reference: <testLibraryFragment>::@setter::a2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _a2 @-1
              type: A
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::a1::@parameter::_a1#element
        synthetic set a2
          reference: <testLibraryFragment>::@setter::a2
          element: <testLibraryFragment>::@setter::a2#element
          formalParameters
            <null-name>
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
    synthetic static get a2
      firstFragment: <testLibraryFragment>::@getter::a2
  setters
    synthetic static set a1
      firstFragment: <testLibraryFragment>::@setter::a1
      formalParameters
        requiredPositional _a1
          type: A
    synthetic static set a2
      firstFragment: <testLibraryFragment>::@setter::a2
      formalParameters
        requiredPositional _a2
          type: A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static v @71
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: List<Object Function(int Function(String))>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: List<Object Function(int Function(String))>
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: List<Object Function(int Function(String))>
          returnType: void
      functions
        f @4
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional x @10
              type: int Function(String)
              parameters
                requiredPositional y @19
                  type: String
          returnType: int
        g @39
          reference: <testLibraryFragment>::@function::g
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional x @45
              type: int Function(String)
              parameters
                requiredPositional y @54
                  type: String
          returnType: String
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: List<Object Function(int Function(String))>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        abstract class A @15
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          methods
            abstract m @25
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
        abstract class B @48
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
          methods
            abstract m @61
              reference: <testLibraryFragment>::@class::B::@method::m
              enclosingElement3: <testLibraryFragment>::@class::B
              returnType: String
        abstract class C @84
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          interfaces
            A
            B
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
        abstract class D @121
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          supertype: C
          fields
            f @141
              reference: <testLibraryFragment>::@class::D::@field::f
              enclosingElement3: <testLibraryFragment>::@class::D
              type: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
              superConstructor: <testLibraryFragment>::@class::C::@constructor::new
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::D::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::D
              returnType: dynamic
            synthetic set f= @-1
              reference: <testLibraryFragment>::@class::D::@setter::f
              enclosingElement3: <testLibraryFragment>::@class::D
              parameters
                requiredPositional _f @-1
                  type: dynamic
              returnType: void
----------------------------------------
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
              superConstructor: <testLibraryFragment>::@class::C::@constructor::new
          getters
            synthetic get f
              reference: <testLibraryFragment>::@class::D::@getter::f
              element: <testLibraryFragment>::@class::D::@getter::f#element
          setters
            synthetic set f
              reference: <testLibraryFragment>::@class::D::@setter::f
              element: <testLibraryFragment>::@class::D::@setter::f#element
              formalParameters
                <null-name>
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
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: <testLibraryFragment>::@class::A::@method::m
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      methods
        abstract m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: <testLibraryFragment>::@class::B::@method::m
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
      setters
        synthetic set f
          firstFragment: <testLibraryFragment>::@class::D::@setter::f
          formalParameters
            requiredPositional _f
              type: dynamic
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
          methods
            call @19
              reference: <testLibraryFragment>::@class::A::@method::call
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: double
        class B @42
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          fields
            a @50
              reference: <testLibraryFragment>::@class::B::@field::a
              enclosingElement3: <testLibraryFragment>::@class::B
              type: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
          accessors
            synthetic get a @-1
              reference: <testLibraryFragment>::@class::B::@getter::a
              enclosingElement3: <testLibraryFragment>::@class::B
              returnType: A
            synthetic set a= @-1
              reference: <testLibraryFragment>::@class::B::@setter::a
              enclosingElement3: <testLibraryFragment>::@class::B
              parameters
                requiredPositional _a @-1
                  type: A
              returnType: void
      topLevelVariables
        static c @59
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: double
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: double
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: double
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
                <null-name>
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
            <null-name>
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
          reference: <testLibrary>::@class::A::@method::call
          firstFragment: <testLibraryFragment>::@class::A::@method::call
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
      setters
        synthetic set a
          firstFragment: <testLibraryFragment>::@class::B::@setter::a
          formalParameters
            requiredPositional _a
              type: A
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
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: double
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int Function()
          shouldUseTypeForInitializerInference: false
        static b @42
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int Function()
        synthetic static set a= @-1
          reference: <testLibraryFragment>::@setter::a
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _a @-1
              type: int Function()
          returnType: void
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set b= @-1
          reference: <testLibraryFragment>::@setter::b
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _b @-1
              type: int
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::a::@parameter::_a#element
        synthetic set b
          reference: <testLibraryFragment>::@setter::b
          element: <testLibraryFragment>::@setter::b#element
          formalParameters
            <null-name>
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
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
  setters
    synthetic static set a
      firstFragment: <testLibraryFragment>::@setter::a
      formalParameters
        requiredPositional _a
          type: int Function()
    synthetic static set b
      firstFragment: <testLibraryFragment>::@setter::b
      formalParameters
        requiredPositional _b
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart deferred as a @28
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        a @28
          reference: <testLibraryFragment>::@prefix::a
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static x @35
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Future<dynamic> Function()
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Future<dynamic> Function()
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: Future<dynamic> Function()
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: Future<dynamic> Function()
''');
  }

  test_type_inference_closure_with_function_typed_parameter() async {
    var library = await buildLibrary('''
var x = (int f(String x)) => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int Function(int Function(String))
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int Function(int Function(String))
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: int Function(int Function(String))
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int Function(int Function(String))
''');
  }

  test_type_inference_closure_with_function_typed_parameter_new() async {
    var library = await buildLibrary('''
var x = (int Function(String) f) => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int Function(int Function(String))
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int Function(int Function(String))
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: int Function(int Function(String))
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int Function(int Function(String))
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static y @21
          reference: <testLibraryFragment>::@topLevelVariable::y
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get y @-1
          reference: <testLibraryFragment>::@getter::y
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set y= @-1
          reference: <testLibraryFragment>::@setter::y
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _y @-1
              type: int
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set y
      firstFragment: <testLibraryFragment>::@setter::y
      formalParameters
        requiredPositional _y
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            static final x @25
              reference: <testLibraryFragment>::@class::A::@field::x
              enclosingElement3: <testLibraryFragment>::@class::A
              typeInferenceError: dependencyCycle
                arguments: [x, y]
              type: dynamic
              shouldUseTypeForInitializerInference: false
            static final y @51
              reference: <testLibraryFragment>::@class::A::@field::y
              enclosingElement3: <testLibraryFragment>::@class::A
              typeInferenceError: dependencyCycle
                arguments: [x, y]
              type: dynamic
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            synthetic static get x @-1
              reference: <testLibraryFragment>::@class::A::@getter::x
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: dynamic
            synthetic static get y @-1
              reference: <testLibraryFragment>::@class::A::@getter::y
              enclosingElement3: <testLibraryFragment>::@class::A
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
        synthetic static get y
          firstFragment: <testLibraryFragment>::@class::A::@getter::y
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            static final a @25
              reference: <testLibraryFragment>::@class::A::@field::a
              enclosingElement3: <testLibraryFragment>::@class::A
              typeInferenceError: dependencyCycle
                arguments: [a, c]
              type: dynamic
              shouldUseTypeForInitializerInference: false
            static final b @49
              reference: <testLibraryFragment>::@class::A::@field::b
              enclosingElement3: <testLibraryFragment>::@class::A
              type: A
              shouldUseTypeForInitializerInference: false
            final c @66
              reference: <testLibraryFragment>::@class::A::@field::c
              enclosingElement3: <testLibraryFragment>::@class::A
              typeInferenceError: dependencyCycle
                arguments: [a, c]
              type: dynamic
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@class::A::@getter::a
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: dynamic
            synthetic static get b @-1
              reference: <testLibraryFragment>::@class::A::@getter::b
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: A
            synthetic get c @-1
              reference: <testLibraryFragment>::@class::A::@getter::c
              enclosingElement3: <testLibraryFragment>::@class::A
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
        synthetic static get b
          firstFragment: <testLibraryFragment>::@class::A::@getter::b
        synthetic get c
          firstFragment: <testLibraryFragment>::@class::A::@getter::c
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
          fields
            value @17
              reference: <testLibraryFragment>::@class::A::@field::value
              enclosingElement3: <testLibraryFragment>::@class::A
              type: T
          constructors
            @27
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional final hasImplicitType this.value @34
                  type: T
                  field: <testLibraryFragment>::@class::A::@field::value
          accessors
            synthetic get value @-1
              reference: <testLibraryFragment>::@class::A::@getter::value
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: T
            synthetic set value= @-1
              reference: <testLibraryFragment>::@class::A::@setter::value
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _value @-1
                  type: T
              returnType: void
        class B @51
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          fields
            a @61
              reference: <testLibraryFragment>::@class::B::@field::a
              enclosingElement3: <testLibraryFragment>::@class::B
              type: A<String>
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
          accessors
            synthetic get a @-1
              reference: <testLibraryFragment>::@class::B::@getter::a
              enclosingElement3: <testLibraryFragment>::@class::B
              returnType: A<String>
            synthetic set a= @-1
              reference: <testLibraryFragment>::@class::B::@setter::a
              enclosingElement3: <testLibraryFragment>::@class::B
              parameters
                requiredPositional _a @-1
                  type: A<String>
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
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: <not-implemented>
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
                <null-name>
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
                <null-name>
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
      setters
        synthetic set value
          firstFragment: <testLibraryFragment>::@class::A::@setter::value
          formalParameters
            requiredPositional _value
              type: T
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
      setters
        synthetic set a
          firstFragment: <testLibraryFragment>::@class::B::@setter::a
          formalParameters
            requiredPositional _a
              type: A<String>
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
          fields
            value @17
              reference: <testLibraryFragment>::@class::A::@field::value
              enclosingElement3: <testLibraryFragment>::@class::A
              type: T
          constructors
            @27
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional final hasImplicitType this.value @34
                  type: T
                  field: <testLibraryFragment>::@class::A::@field::value
          accessors
            synthetic get value @-1
              reference: <testLibraryFragment>::@class::A::@getter::value
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: T
            synthetic set value= @-1
              reference: <testLibraryFragment>::@class::A::@setter::value
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _value @-1
                  type: T
              returnType: void
        class alias B @51
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @53
              defaultType: dynamic
          supertype: A<T>
          mixins
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
              parameters
                requiredPositional final value @-1
                  type: T
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      SimpleIdentifier
                        token: value @-1
                        staticElement: <testLibraryFragment>::@class::B::@constructor::new::@parameter::value
                        element: <testLibraryFragment>::@class::B::@constructor::new::@parameter::value#element
                        staticType: T
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: T}
        class C @78
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            a @88
              reference: <testLibraryFragment>::@class::C::@field::a
              enclosingElement3: <testLibraryFragment>::@class::C
              type: B<int>
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get a @-1
              reference: <testLibraryFragment>::@class::C::@getter::a
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: B<int>
            synthetic set a= @-1
              reference: <testLibraryFragment>::@class::C::@setter::a
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _a @-1
                  type: B<int>
              returnType: void
      mixins
        mixin M @112
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
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: <not-implemented>
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
                <null-name>
                  element: <testLibraryFragment>::@class::A::@setter::value::@parameter::_value#element
        class B @51
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T @53
              element: <not-implemented>
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
              formalParameters
                <null-name>
                  element: <testLibraryFragment>::@class::B::@constructor::new::@parameter::value#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      SimpleIdentifier
                        token: value @-1
                        staticElement: <testLibraryFragment>::@class::B::@constructor::new::@parameter::value
                        element: <testLibraryFragment>::@class::B::@constructor::new::@parameter::value#element
                        staticType: T
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: T}
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
                <null-name>
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
      setters
        synthetic set value
          firstFragment: <testLibraryFragment>::@class::A::@setter::value
          formalParameters
            requiredPositional _value
              type: T
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
      setters
        synthetic set a
          firstFragment: <testLibraryFragment>::@class::C::@setter::a
          formalParameters
            requiredPositional _a
              type: B<int>
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
          fields
            f @19
              reference: <testLibraryFragment>::@class::A::@field::f
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
              shouldUseTypeForInitializerInference: false
          constructors
            @28
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional final hasImplicitType this.f @35
                  type: int
                  field: <testLibraryFragment>::@class::A::@field::f
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::A::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
            synthetic set f= @-1
              reference: <testLibraryFragment>::@class::A::@setter::f
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _f @-1
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
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: <not-implemented>
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
                <null-name>
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
      setters
        synthetic set f
          firstFragment: <testLibraryFragment>::@class::A::@setter::f
          formalParameters
            requiredPositional _f
              type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            @12
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional hasImplicitType _ @14
                  type: dynamic
      topLevelVariables
        static final a @26
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final b @48
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
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
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
        package:test/b.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static v @38
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: InvalidType
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: InvalidType
''');
  }

  test_type_inference_nested_function() async {
    var library = await buildLibrary('''
var x = (t) => (u) => t + u;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function(dynamic) Function(dynamic)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function(dynamic) Function(dynamic)
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: dynamic Function(dynamic) Function(dynamic)
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: dynamic Function(dynamic) Function(dynamic)
''');
  }

  test_type_inference_nested_function_with_parameter_types() async {
    var library = await buildLibrary('''
var x = (int t) => (int u) => t + u;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int Function(int) Function(int)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int Function(int) Function(int)
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: int Function(int) Function(int)
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int Function(int) Function(int)
''');
  }

  test_type_inference_of_closure_with_default_value() async {
    var library = await buildLibrary('''
var x = ([y: 0]) => y;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function([dynamic])
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function([dynamic])
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: dynamic Function([dynamic])
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: dynamic Function([dynamic])
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static final a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final c @32
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
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
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static final a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final c @32
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
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
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static final a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, d]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final c @36
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final d @49
          reference: <testLibraryFragment>::@topLevelVariable::d
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, d]
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get d @-1
          reference: <testLibraryFragment>::@getter::d
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
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
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get d
      firstFragment: <testLibraryFragment>::@getter::d
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static final a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final c @36
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
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
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
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
        class B @18
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class C @40
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @42
              bound: A
              defaultType: A
          fields
            final f @67
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement3: <testLibraryFragment>::@class::C
              type: T
          constructors
            const @78
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional final hasImplicitType this.f @85
                  type: T
                  field: <testLibraryFragment>::@class::C::@field::f
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: T
      topLevelVariables
        static final b @98
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: B
          shouldUseTypeForInitializerInference: false
        static final c @113
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C<B>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: B
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C<B>
----------------------------------------
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
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class C @40
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @42
              element: <not-implemented>
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
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      extensions
        <null> @-1
          reference: <testLibraryFragment>::@extension::0
          enclosingElement3: <testLibraryFragment>
          extendedType: String
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@extension::0::@field::foo
              enclosingElement3: <testLibraryFragment>::@extension::0
              type: int
          accessors
            get foo @32
              reference: <testLibraryFragment>::@extension::0::@getter::foo
              enclosingElement3: <testLibraryFragment>::@extension::0
              returnType: int
      topLevelVariables
        static v @48
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
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
      extensions
        extension <null-name>
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
            <null-name>
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
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              bound: dynamic
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      typeAliases
        functionTypeAliasBased F @34
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function(dynamic)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional p @38
                type: dynamic
            returnType: dynamic
      topLevelVariables
        static V2 @56
          reference: <testLibraryFragment>::@topLevelVariable::V2
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: true
        static V @71
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get V2 @-1
          reference: <testLibraryFragment>::@getter::V2
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static set V2= @-1
          reference: <testLibraryFragment>::@setter::V2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _V2 @-1
              type: dynamic
          returnType: void
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set V= @-1
          reference: <testLibraryFragment>::@setter::V
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _V @-1
              type: int
          returnType: void
      functions
        f @44
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional p @48
              type: dynamic
          returnType: dynamic
----------------------------------------
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
              element: <not-implemented>
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
            <null-name>
              element: <testLibraryFragment>::@setter::V2::@parameter::_V2#element
        synthetic set V
          reference: <testLibraryFragment>::@setter::V
          element: <testLibraryFragment>::@setter::V#element
          formalParameters
            <null-name>
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
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
  setters
    synthetic static set V2
      firstFragment: <testLibraryFragment>::@setter::V2
      formalParameters
        requiredPositional _V2
          type: dynamic
    synthetic static set V
      firstFragment: <testLibraryFragment>::@setter::V
      formalParameters
        requiredPositional _V
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static V @4
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: dynamic
        static V2 @22
          reference: <testLibraryFragment>::@topLevelVariable::V2
          enclosingElement3: <testLibraryFragment>
          type: List<dynamic>
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static set V= @-1
          reference: <testLibraryFragment>::@setter::V
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _V @-1
              type: dynamic
          returnType: void
        synthetic static get V2 @-1
          reference: <testLibraryFragment>::@getter::V2
          enclosingElement3: <testLibraryFragment>
          returnType: List<dynamic>
        synthetic static set V2= @-1
          reference: <testLibraryFragment>::@setter::V2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _V2 @-1
              type: List<dynamic>
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::V::@parameter::_V#element
        synthetic set V2
          reference: <testLibraryFragment>::@setter::V2
          element: <testLibraryFragment>::@setter::V2#element
          formalParameters
            <null-name>
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
    synthetic static get V2
      firstFragment: <testLibraryFragment>::@getter::V2
  setters
    synthetic static set V
      firstFragment: <testLibraryFragment>::@setter::V
      formalParameters
        requiredPositional _V
          type: dynamic
    synthetic static set V2
      firstFragment: <testLibraryFragment>::@setter::V2
      formalParameters
        requiredPositional _V2
          type: List<dynamic>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            m @15
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional p @21
                  type: InvalidType
              returnType: dynamic
----------------------------------------
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
              element: <not-implemented>
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
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: <testLibraryFragment>::@class::C::@method::m
          formalParameters
            requiredPositional p
              type: InvalidType
''');
  }

  test_type_invalid_unresolvedPrefix() async {
    var library = await buildLibrary('''
p.C v;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static v @4
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: InvalidType
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: InvalidType
''');
  }

  test_type_never() async {
    var library = await buildLibrary('Never d;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static d @6
          reference: <testLibraryFragment>::@topLevelVariable::d
          enclosingElement3: <testLibraryFragment>
          type: Never
      accessors
        synthetic static get d @-1
          reference: <testLibraryFragment>::@getter::d
          enclosingElement3: <testLibraryFragment>
          returnType: Never
        synthetic static set d= @-1
          reference: <testLibraryFragment>::@setter::d
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _d @-1
              type: Never
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set d
      firstFragment: <testLibraryFragment>::@setter::d
      formalParameters
        requiredPositional _d
          type: Never
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            t @17
              reference: <testLibraryFragment>::@class::C::@field::t
              enclosingElement3: <testLibraryFragment>::@class::C
              type: T
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get t @-1
              reference: <testLibraryFragment>::@class::C::@getter::t
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: T
            synthetic set t= @-1
              reference: <testLibraryFragment>::@class::C::@setter::t
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _t @-1
                  type: T
              returnType: void
----------------------------------------
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
              element: <not-implemented>
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
                <null-name>
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
          type: T
          getter: <testLibraryFragment>::@class::C::@getter::t#element
          setter: <testLibraryFragment>::@class::C::@setter::t#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get t
          firstFragment: <testLibraryFragment>::@class::C::@getter::t
      setters
        synthetic set t
          firstFragment: <testLibraryFragment>::@class::C::@setter::t
          formalParameters
            requiredPositional _t
              type: T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            t @18
              reference: <testLibraryFragment>::@class::C::@field::t
              enclosingElement3: <testLibraryFragment>::@class::C
              type: T?
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get t @-1
              reference: <testLibraryFragment>::@class::C::@getter::t
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: T?
            synthetic set t= @-1
              reference: <testLibraryFragment>::@class::C::@setter::t
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _t @-1
                  type: T?
              returnType: void
----------------------------------------
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
              element: <not-implemented>
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
                <null-name>
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
          type: T?
          getter: <testLibraryFragment>::@class::C::@getter::t#element
          setter: <testLibraryFragment>::@class::C::@setter::t#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get t
          firstFragment: <testLibraryFragment>::@class::C::@getter::t
      setters
        synthetic set t
          firstFragment: <testLibraryFragment>::@class::C::@setter::t
          formalParameters
            requiredPositional _t
              type: T?
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
      enums
        enum E @16
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @20
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibrary>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      typeAliases
        functionTypeAliasBased F @32
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
      topLevelVariables
        static c @39
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C
        static e @44
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement3: <testLibraryFragment>
          type: E
        static f @49
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement3: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: <testLibraryFragment>::@typeAlias::F
          returnType: void
----------------------------------------
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
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
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
            <null-name>
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            <null-name>
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
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
        alias: <testLibraryFragment>::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
''');
  }

  test_type_reference_lib_to_part() async {
    newFile('$testPackageLibPath/a.dart',
        'part of l; class C {} enum E { v } typedef F();');
    var library =
        await buildLibrary('library l; part "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  name: l
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        static c @28
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C
        static e @33
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement3: <testLibraryFragment>
          type: E
        static f @38
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement3: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class C @17
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::C
      enums
        enum E @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          supertype: Enum
          fields
            static const enumConstant v @31
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::E
                      element2: <testLibrary>::@enum::E
                      type: E
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
                    element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              returnType: List<E>
      typeAliases
        functionTypeAliasBased F @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  name: l
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
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
            <null-name>
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            <null-name>
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
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
            synthetic values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values#element
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
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
          type: List<E>
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
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
        alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
''');
  }

  test_type_reference_part_to_lib() async {
    newFile('$testPackageLibPath/a.dart', 'part of l; C c; E e; F f;');
    var library = await buildLibrary(
        'library l; part "a.dart"; class C {} enum E { v } typedef F();');
    checkElementText(library, r'''
library
  name: l
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class C @32
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      enums
        enum E @42
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @46
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibrary>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      typeAliases
        functionTypeAliasBased F @58
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @13
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::c
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: C
        static e @18
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::e
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: E
        static f @23
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::c
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: C
        synthetic static set c= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::c
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::e
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: E
        synthetic static set e= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::e
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::f
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: <testLibraryFragment>::@typeAlias::F
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  name: l
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
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
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
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
            <null-name>
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::e
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::f
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::f#element
          formalParameters
            <null-name>
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
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
        alias: <testLibraryFragment>::@typeAlias::F
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::f#element
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::c
    synthetic static get e
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::e
    synthetic static get f
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
''');
  }

  test_type_reference_part_to_other_part() async {
    newFile('$testPackageLibPath/a.dart',
        'part of l; class C {} enum E { v } typedef F();');
    newFile('$testPackageLibPath/b.dart', 'part of l; C c; E e; F f;');
    var library =
        await buildLibrary('library l; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library
  name: l
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class C @17
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::C
      enums
        enum E @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          supertype: Enum
          fields
            static const enumConstant v @31
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::E
                      element2: <testLibrary>::@enum::E
                      type: E
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
                    element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              returnType: List<E>
      typeAliases
        functionTypeAliasBased F @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @13
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::c
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          type: C
        static e @18
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::e
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          type: E
        static f @23
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::f
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          type: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::c
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          returnType: C
        synthetic static set c= @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::c
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::e
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          returnType: E
        synthetic static set e= @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::e
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::f
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          returnType: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::f
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  name: l
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
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
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
            synthetic values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values#element
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
            <null-name>
              element: <testLibrary>::@fragment::package:test/b.dart::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::e
          element: <testLibrary>::@fragment::package:test/b.dart::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibrary>::@fragment::package:test/b.dart::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::f
          element: <testLibrary>::@fragment::package:test/b.dart::@setter::f#element
          formalParameters
            <null-name>
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
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
          type: List<E>
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
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
        alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      getter: <testLibrary>::@fragment::package:test/b.dart::@getter::f#element
      setter: <testLibrary>::@fragment::package:test/b.dart::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@getter::c
    synthetic static get e
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@getter::e
    synthetic static get f
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
''');
  }

  test_type_reference_part_to_part() async {
    newFile('$testPackageLibPath/a.dart',
        'part of l; class C {} enum E { v } typedef F(); C c; E e; F f;');
    var library = await buildLibrary('library l; part "a.dart";');
    checkElementText(library, r'''
library
  name: l
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class C @17
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::C
      enums
        enum E @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          supertype: Enum
          fields
            static const enumConstant v @31
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::E
                      element2: <testLibrary>::@enum::E
                      type: E
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
                    element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              returnType: List<E>
      typeAliases
        functionTypeAliasBased F @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
      topLevelVariables
        static c @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::c
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: C
        static e @55
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::e
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: E
        static f @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::c
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: C
        synthetic static set c= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::c
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::e
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: E
        synthetic static set e= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::e
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::f
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  name: l
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
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
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
            synthetic values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values#element
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
            <null-name>
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::e
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::f
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::f#element
          formalParameters
            <null-name>
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
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
          type: List<E>
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
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
        alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::f#element
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::c
    synthetic static get e
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::e
    synthetic static get f
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
''');
  }

  test_type_reference_to_class() async {
    var library = await buildLibrary('class C {} C c;');
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
      topLevelVariables
        static c @13
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
----------------------------------------
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
            <null-name>
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
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
''');
  }

  test_type_reference_to_class_with_type_arguments() async {
    var library = await buildLibrary('class C<T, U> {} C<int, String> c;');
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
          typeParameters
            covariant T @8
              defaultType: dynamic
            covariant U @11
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static c @32
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C<int, String>
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C<int, String>
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C<int, String>
          returnType: void
----------------------------------------
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
              element: <not-implemented>
            U @11
              element: <not-implemented>
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
            <null-name>
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
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C<int, String>
''');
  }

  test_type_reference_to_class_with_type_arguments_implicit() async {
    var library = await buildLibrary('class C<T, U> {} C c;');
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
          typeParameters
            covariant T @8
              defaultType: dynamic
            covariant U @11
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C<dynamic, dynamic>
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C<dynamic, dynamic>
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C<dynamic, dynamic>
          returnType: void
----------------------------------------
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
              element: <not-implemented>
            U @11
              element: <not-implemented>
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
            <null-name>
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
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C<dynamic, dynamic>
''');
  }

  test_type_reference_to_enum() async {
    var library = await buildLibrary('enum E { v } E e;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @9
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibrary>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static e @15
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement3: <testLibraryFragment>
          type: E
      accessors
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement3: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
----------------------------------------
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
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
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
            <null-name>
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
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
  setters
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
''');
  }

  test_type_reference_to_import() async {
    newFile(
        '$testPackageLibPath/a.dart', 'class C {} enum E { v } typedef F();');
    var library = await buildLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C
        static e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement3: <testLibraryFragment>
          type: E
        static f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/a.dart::<fragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement3: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/a.dart::<fragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: package:test/a.dart::<fragment>::@typeAlias::F
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            <null-name>
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
        alias: package:test/a.dart::<fragment>::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: package:test/a.dart::<fragment>::@typeAlias::F
''');
  }

  test_type_reference_to_import_export() async {
    newFile('$testPackageLibPath/a.dart', 'export "b.dart";');
    newFile(
        '$testPackageLibPath/b.dart', 'class C {} enum E { v } typedef F();');
    var library = await buildLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C
        static e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement3: <testLibraryFragment>
          type: E
        static f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/b.dart::<fragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement3: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/b.dart::<fragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: package:test/b.dart::<fragment>::@typeAlias::F
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            <null-name>
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
        alias: package:test/b.dart::<fragment>::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: package:test/b.dart::<fragment>::@typeAlias::F
''');
  }

  test_type_reference_to_import_export_export() async {
    newFile('$testPackageLibPath/a.dart', 'export "b.dart";');
    newFile('$testPackageLibPath/b.dart', 'export "c.dart";');
    newFile(
        '$testPackageLibPath/c.dart', 'class C {} enum E { v } typedef F();');
    var library = await buildLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C
        static e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement3: <testLibraryFragment>
          type: E
        static f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/c.dart::<fragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement3: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/c.dart::<fragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: package:test/c.dart::<fragment>::@typeAlias::F
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            <null-name>
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
        alias: package:test/c.dart::<fragment>::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: package:test/c.dart::<fragment>::@typeAlias::F
''');
  }

  test_type_reference_to_import_export_export_in_subdirs() async {
    newFile('$testPackageLibPath/a/a.dart', 'export "b/b.dart";');
    newFile('$testPackageLibPath/a/b/b.dart', 'export "../c/c.dart";');
    newFile('$testPackageLibPath/a/c/c.dart',
        'class C {} enum E { v } typedef F();');
    var library = await buildLibrary('import "a/a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @21
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C
        static e @26
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement3: <testLibraryFragment>
          type: E
        static f @31
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/a/c/c.dart::<fragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement3: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/a/c/c.dart::<fragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: package:test/a/c/c.dart::<fragment>::@typeAlias::F
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            <null-name>
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
        alias: package:test/a/c/c.dart::<fragment>::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: package:test/a/c/c.dart::<fragment>::@typeAlias::F
''');
  }

  test_type_reference_to_import_export_in_subdirs() async {
    newFile('$testPackageLibPath/a/a.dart', 'export "b/b.dart";');
    newFile('$testPackageLibPath/a/b/b.dart',
        'class C {} enum E { v } typedef F();');
    var library = await buildLibrary('import "a/a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @21
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C
        static e @26
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement3: <testLibraryFragment>
          type: E
        static f @31
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/a/b/b.dart::<fragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement3: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/a/b/b.dart::<fragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: package:test/a/b/b.dart::<fragment>::@typeAlias::F
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            <null-name>
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
        alias: package:test/a/b/b.dart::<fragment>::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: package:test/a/b/b.dart::<fragment>::@typeAlias::F
''');
  }

  test_type_reference_to_import_part() async {
    newFile('$testPackageLibPath/a.dart', 'library l; part "b.dart";');
    newFile('$testPackageLibPath/b.dart',
        'part of l; class C {} enum E { v } typedef F();');
    var library = await buildLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C
        static e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement3: <testLibraryFragment>
          type: E
        static f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/a.dart::@fragment::package:test/b.dart::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement3: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/a.dart::@fragment::package:test/b.dart::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: package:test/a.dart::@fragment::package:test/b.dart::@typeAlias::F
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            <null-name>
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
        alias: package:test/a.dart::@fragment::package:test/b.dart::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: package:test/a.dart::@fragment::package:test/b.dart::@typeAlias::F
''');
  }

  test_type_reference_to_import_part2() async {
    newFile('$testPackageLibPath/a.dart',
        'library l; part "p1.dart"; part "p2.dart";');
    newFile('$testPackageLibPath/p1.dart', 'part of l; class C1 {}');
    newFile('$testPackageLibPath/p2.dart', 'part of l; class C2 {}');
    var library = await buildLibrary('import "a.dart"; C1 c1; C2 c2;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c1 @20
          reference: <testLibraryFragment>::@topLevelVariable::c1
          enclosingElement3: <testLibraryFragment>
          type: C1
        static c2 @27
          reference: <testLibraryFragment>::@topLevelVariable::c2
          enclosingElement3: <testLibraryFragment>
          type: C2
      accessors
        synthetic static get c1 @-1
          reference: <testLibraryFragment>::@getter::c1
          enclosingElement3: <testLibraryFragment>
          returnType: C1
        synthetic static set c1= @-1
          reference: <testLibraryFragment>::@setter::c1
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c1 @-1
              type: C1
          returnType: void
        synthetic static get c2 @-1
          reference: <testLibraryFragment>::@getter::c2
          enclosingElement3: <testLibraryFragment>
          returnType: C2
        synthetic static set c2= @-1
          reference: <testLibraryFragment>::@setter::c2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c2 @-1
              type: C2
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::c1::@parameter::_c1#element
        synthetic set c2
          reference: <testLibraryFragment>::@setter::c2
          element: <testLibraryFragment>::@setter::c2#element
          formalParameters
            <null-name>
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
    synthetic static get c2
      firstFragment: <testLibraryFragment>::@getter::c2
  setters
    synthetic static set c1
      firstFragment: <testLibraryFragment>::@setter::c1
      formalParameters
        requiredPositional _c1
          type: C1
    synthetic static set c2
      firstFragment: <testLibraryFragment>::@setter::c2
      formalParameters
        requiredPositional _c2
          type: C2
''');
  }

  test_type_reference_to_import_part_in_subdir() async {
    newFile('$testPackageLibPath/a/b.dart', 'library l; part "c.dart";');
    newFile('$testPackageLibPath/a/c.dart',
        'part of l; class C {} enum E { v } typedef F();');
    var library = await buildLibrary('import "a/b.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a/b.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @21
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C
        static e @26
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement3: <testLibraryFragment>
          type: E
        static f @31
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/a/b.dart::@fragment::package:test/a/c.dart::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement3: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/a/b.dart::@fragment::package:test/a/c.dart::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: package:test/a/b.dart::@fragment::package:test/a/c.dart::@typeAlias::F
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            <null-name>
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
        alias: package:test/a/b.dart::@fragment::package:test/a/c.dart::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: package:test/a/b.dart::@fragment::package:test/a/c.dart::@typeAlias::F
''');
  }

  test_type_reference_to_import_relative() async {
    newFile(
        '$testPackageLibPath/a.dart', 'class C {} enum E { v } typedef F();');
    var library = await buildLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C
        static e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement3: <testLibraryFragment>
          type: E
        static f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/a.dart::<fragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement3: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/a.dart::<fragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: package:test/a.dart::<fragment>::@typeAlias::F
          returnType: void
----------------------------------------
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
            <null-name>
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set e
          reference: <testLibraryFragment>::@setter::e
          element: <testLibraryFragment>::@setter::e#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::e::@parameter::_e#element
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            <null-name>
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
        alias: package:test/a.dart::<fragment>::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
    synthetic static set e
      firstFragment: <testLibraryFragment>::@setter::e
      formalParameters
        requiredPositional _e
          type: E
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: package:test/a.dart::<fragment>::@typeAlias::F
''');
  }

  test_type_reference_to_typedef() async {
    var library = await buildLibrary('typedef F(); F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      typeAliases
        functionTypeAliasBased F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
      topLevelVariables
        static f @15
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: <testLibraryFragment>::@typeAlias::F
          returnType: void
----------------------------------------
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
            <null-name>
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
        alias: <testLibraryFragment>::@typeAlias::F
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
''');
  }

  test_type_reference_to_typedef_with_type_arguments() async {
    var library =
        await buildLibrary('typedef U F<T, U>(T t); F<int, String> f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      typeAliases
        functionTypeAliasBased F @10
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @12
              defaultType: dynamic
            covariant U @15
              defaultType: dynamic
          aliasedType: U Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional t @20
                type: T
            returnType: U
      topLevelVariables
        static f @39
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: String Function(int)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                int
                String
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: String Function(int)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                int
                String
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: String Function(int)
                alias: <testLibraryFragment>::@typeAlias::F
                  typeArguments
                    int
                    String
          returnType: void
----------------------------------------
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
              element: <not-implemented>
            U @15
              element: <not-implemented>
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
            <null-name>
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
        alias: <testLibraryFragment>::@typeAlias::F
          typeArguments
            int
            String
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: String Function(int)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                int
                String
''');
  }

  test_type_reference_to_typedef_with_type_arguments_implicit() async {
    var library = await buildLibrary('typedef U F<T, U>(T t); F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      typeAliases
        functionTypeAliasBased F @10
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @12
              defaultType: dynamic
            covariant U @15
              defaultType: dynamic
          aliasedType: U Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional t @20
                type: T
            returnType: U
      topLevelVariables
        static f @26
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function(dynamic)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                dynamic
                dynamic
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function(dynamic)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                dynamic
                dynamic
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function(dynamic)
                alias: <testLibraryFragment>::@typeAlias::F
                  typeArguments
                    dynamic
                    dynamic
          returnType: void
----------------------------------------
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
              element: <not-implemented>
            U @15
              element: <not-implemented>
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
            <null-name>
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
        alias: <testLibraryFragment>::@typeAlias::F
          typeArguments
            dynamic
            dynamic
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function(dynamic)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                dynamic
                dynamic
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
