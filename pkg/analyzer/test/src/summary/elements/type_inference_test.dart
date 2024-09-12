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
      enclosingElement: <testLibrary>
      topLevelVariables
        static final f @6
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: V Function<U, V>(U, V)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: V Function<U, V>(U, V)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final f @6
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
      getters
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
  topLevelVariables
    final f
      reference: <none>
      type: V Function<U, V>(U, V)
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
  getters
    synthetic static get f
      reference: <none>
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
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static final f @19
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: double Function(int)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get f @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
      previousFragment: <testLibraryFragment>
      topLevelVariables
        final f @19
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
          element: <none>
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::f
      getters
        get f @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          element: <none>
  topLevelVariables
    final f
      reference: <none>
      type: double Function(int)
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
      getter: <none>
  getters
    synthetic static get f
      reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            final f @21
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement: <testLibraryFragment>::@class::C
              type: InvalidType
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement: <testLibraryFragment>::@class::C
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @8
              element: <none>
          fields
            f @21
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final f
          reference: <none>
          type: InvalidType
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class C @43
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant V @45
              defaultType: dynamic
          constructors
            const @58
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional f @65
                  type: D<V, U> Function<U>()
                    alias: <testLibraryFragment>::@typeAlias::F
                      typeArguments
                        V
        class D @77
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @79
              defaultType: dynamic
            covariant U @81
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
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
          enclosingElement: <testLibraryFragment>
          type: C<int>
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @122
              constructorName: ConstructorName
                type: NamedType
                  name: C @128
                  element: <testLibraryFragment>::@class::C
                  type: C<int>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::C::@constructor::new
                  substitution: {V: int}
              argumentList: ArgumentList
                leftParenthesis: ( @129
                arguments
                  SimpleIdentifier
                    token: f @130
                    staticElement: <testLibraryFragment>::@function::f
                    staticType: D<int, U> Function<U>()
                rightParenthesis: ) @131
              staticType: C<int>
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: C<int>
      functions
        f @96
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            V @45
              element: <none>
          constructors
            const new @58
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              parameters
                f @65
                  element: <none>
        class D @77
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          typeParameters
            T @79
              element: <none>
            U @81
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @10
              element: <none>
      topLevelVariables
        const x @118
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      functions
        f @96
          reference: <testLibraryFragment>::@function::f
          element: <none>
          typeParameters
            U @98
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        V
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional f
              reference: <none>
              type: D<V, U> Function<U>()
                alias: <testLibraryFragment>::@typeAlias::F
                  typeArguments
                    V
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibraryFragment>::@class::D
      typeParameters
        T
        U
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  typeAliases
    F
      reference: <none>
      typeParameters
        T
      aliasedType: D<T, U> Function<U>()
  topLevelVariables
    const x
      reference: <none>
      type: C<int>
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  functions
    f
      reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class C @38
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            const @50
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional f @54
                  type: D<T> Function<T>()
                    alias: <testLibraryFragment>::@typeAlias::F
        class D @66
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @68
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
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
          enclosingElement: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              keyword: const @105
              constructorName: ConstructorName
                type: NamedType
                  name: C @111
                  element: <testLibraryFragment>::@class::C
                  type: C
                staticElement: <testLibraryFragment>::@class::C::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @112
                arguments
                  SimpleIdentifier
                    token: f @113
                    staticElement: <testLibraryFragment>::@function::f
                    staticType: D<T> Function<T>()
                rightParenthesis: ) @114
              staticType: C
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: C
      functions
        f @79
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C
          constructors
            const new @50
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              parameters
                f @54
                  element: <none>
        class D @66
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          typeParameters
            T @68
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
      topLevelVariables
        const x @101
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      functions
        f @79
          reference: <testLibraryFragment>::@function::f
          element: <none>
          typeParameters
            T @81
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional f
              reference: <none>
              type: D<T> Function<T>()
                alias: <testLibraryFragment>::@typeAlias::F
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibraryFragment>::@class::D
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  typeAliases
    F
      reference: <none>
      aliasedType: D<T> Function<T>()
  topLevelVariables
    const x
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  functions
    f
      reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @18
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class S @40
          reference: <testLibraryFragment>::@class::S
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @42
              bound: A
              defaultType: A
          constructors
            @59
              reference: <testLibraryFragment>::@class::S::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::S
              parameters
                requiredPositional _ @63
                  type: T
      topLevelVariables
        static s @74
          reference: <testLibraryFragment>::@topLevelVariable::s
          enclosingElement: <testLibraryFragment>
          type: S<B>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get s @-1
          reference: <testLibraryFragment>::@getter::s
          enclosingElement: <testLibraryFragment>
          returnType: S<B>
        synthetic static set s= @-1
          reference: <testLibraryFragment>::@setter::s
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @18
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class S @40
          reference: <testLibraryFragment>::@class::S
          element: <testLibraryFragment>::@class::S
          typeParameters
            T @42
              element: <none>
          constructors
            new @59
              reference: <testLibraryFragment>::@class::S::@constructor::new
              element: <none>
              parameters
                _ @63
                  element: <none>
      topLevelVariables
        s @74
          reference: <testLibraryFragment>::@topLevelVariable::s
          element: <none>
          getter2: <testLibraryFragment>::@getter::s
          setter2: <testLibraryFragment>::@setter::s
      getters
        get s @-1
          reference: <testLibraryFragment>::@getter::s
          element: <none>
      setters
        set s= @-1
          reference: <testLibraryFragment>::@setter::s
          element: <none>
          parameters
            _s @-1
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class S
      reference: <testLibraryFragment>::@class::S
      typeParameters
        T
          bound: A
      firstFragment: <testLibraryFragment>::@class::S
      constructors
        new
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: T
          firstFragment: <testLibraryFragment>::@class::S::@constructor::new
  topLevelVariables
    s
      reference: <none>
      type: S<B>
      firstFragment: <testLibraryFragment>::@topLevelVariable::s
      getter: <none>
      setter: <none>
  getters
    synthetic static get s
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::s
  setters
    synthetic static set s=
      reference: <none>
      parameters
        requiredPositional _s
          reference: <none>
          type: S<B>
      firstFragment: <testLibraryFragment>::@setter::s
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            b @14
              reference: <testLibraryFragment>::@class::A::@field::b
              enclosingElement: <testLibraryFragment>::@class::A
              type: B
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          accessors
            synthetic get b @-1
              reference: <testLibraryFragment>::@class::A::@getter::b
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: B
            synthetic set b= @-1
              reference: <testLibraryFragment>::@class::A::@setter::b
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _b @-1
                  type: B
              returnType: void
        class B @25
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          fields
            synthetic c @-1
              reference: <testLibraryFragment>::@class::B::@field::c
              enclosingElement: <testLibraryFragment>::@class::B
              type: C
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
          accessors
            get c @37
              reference: <testLibraryFragment>::@class::B::@getter::c
              enclosingElement: <testLibraryFragment>::@class::B
              returnType: C
            set c= @59
              reference: <testLibraryFragment>::@class::B::@setter::c
              enclosingElement: <testLibraryFragment>::@class::B
              parameters
                requiredPositional value @63
                  type: C
              returnType: void
        class C @81
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
        class D @92
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          supertype: C
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
              superConstructor: <testLibraryFragment>::@class::C::@constructor::new
      topLevelVariables
        static a @111
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: A
          shouldUseTypeForInitializerInference: false
        static x @128
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: A
        synthetic static set a= @-1
          reference: <testLibraryFragment>::@setter::a
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _a @-1
              type: A
          returnType: void
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A
          fields
            b @14
              reference: <testLibraryFragment>::@class::A::@field::b
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::b
              setter2: <testLibraryFragment>::@class::A::@setter::b
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          getters
            get b @-1
              reference: <testLibraryFragment>::@class::A::@getter::b
              element: <none>
          setters
            set b= @-1
              reference: <testLibraryFragment>::@class::A::@setter::b
              element: <none>
              parameters
                _b @-1
                  element: <none>
        class B @25
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          fields
            c @-1
              reference: <testLibraryFragment>::@class::B::@field::c
              element: <none>
              getter2: <testLibraryFragment>::@class::B::@getter::c
              setter2: <testLibraryFragment>::@class::B::@setter::c
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
          getters
            get c @37
              reference: <testLibraryFragment>::@class::B::@getter::c
              element: <none>
          setters
            set c= @59
              reference: <testLibraryFragment>::@class::B::@setter::c
              element: <none>
              parameters
                value @63
                  element: <none>
        class C @81
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
        class D @92
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
              superConstructor: <testLibraryFragment>::@class::C::@constructor::new
      topLevelVariables
        a @111
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
          setter2: <testLibraryFragment>::@setter::a
        x @128
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set a= @-1
          reference: <testLibraryFragment>::@setter::a
          element: <none>
          parameters
            _a @-1
              element: <none>
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        b
          reference: <none>
          type: B
          firstFragment: <testLibraryFragment>::@class::A::@field::b
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get b
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::b
      setters
        synthetic set b=
          reference: <none>
          parameters
            requiredPositional _b
              reference: <none>
              type: B
          firstFragment: <testLibraryFragment>::@class::A::@setter::b
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        synthetic c
          reference: <none>
          type: C
          firstFragment: <testLibraryFragment>::@class::B::@field::c
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      getters
        get c
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@getter::c
      setters
        set c=
          reference: <none>
          parameters
            requiredPositional value
              reference: <none>
              type: C
          firstFragment: <testLibraryFragment>::@class::B::@setter::c
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      supertype: C
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  topLevelVariables
    a
      reference: <none>
      type: A
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
      setter: <none>
    x
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set a=
      reference: <none>
      parameters
        requiredPositional _a
          reference: <none>
          type: A
      firstFragment: <testLibraryFragment>::@setter::a
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: C
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: Iterable<String>
          shouldUseTypeForInitializerInference: false
        static y @40
          reference: <testLibraryFragment>::@topLevelVariable::y
          enclosingElement: <testLibraryFragment>
          type: List<int>
          shouldUseTypeForInitializerInference: false
        static z @53
          reference: <testLibraryFragment>::@topLevelVariable::z
          enclosingElement: <testLibraryFragment>
          type: List<String>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: Iterable<String>
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: Iterable<String>
          returnType: void
        synthetic static get y @-1
          reference: <testLibraryFragment>::@getter::y
          enclosingElement: <testLibraryFragment>
          returnType: List<int>
        synthetic static set y= @-1
          reference: <testLibraryFragment>::@setter::y
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _y @-1
              type: List<int>
          returnType: void
        synthetic static get z @-1
          reference: <testLibraryFragment>::@getter::z
          enclosingElement: <testLibraryFragment>
          returnType: List<String>
        synthetic static set z= @-1
          reference: <testLibraryFragment>::@setter::z
          enclosingElement: <testLibraryFragment>
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
        x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
        y @40
          reference: <testLibraryFragment>::@topLevelVariable::y
          element: <none>
          getter2: <testLibraryFragment>::@getter::y
          setter2: <testLibraryFragment>::@setter::y
        z @53
          reference: <testLibraryFragment>::@topLevelVariable::z
          element: <none>
          getter2: <testLibraryFragment>::@getter::z
          setter2: <testLibraryFragment>::@setter::z
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
        get y @-1
          reference: <testLibraryFragment>::@getter::y
          element: <none>
        get z @-1
          reference: <testLibraryFragment>::@getter::z
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
        set y= @-1
          reference: <testLibraryFragment>::@setter::y
          element: <none>
          parameters
            _y @-1
              element: <none>
        set z= @-1
          reference: <testLibraryFragment>::@setter::z
          element: <none>
          parameters
            _z @-1
              element: <none>
  topLevelVariables
    x
      reference: <none>
      type: Iterable<String>
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
    y
      reference: <none>
      type: List<int>
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      getter: <none>
      setter: <none>
    z
      reference: <none>
      type: List<String>
      firstFragment: <testLibraryFragment>::@topLevelVariable::z
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
    synthetic static get y
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::y
    synthetic static get z
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::z
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: Iterable<String>
      firstFragment: <testLibraryFragment>::@setter::x
    synthetic static set y=
      reference: <none>
      parameters
        requiredPositional _y
          reference: <none>
          type: List<int>
      firstFragment: <testLibraryFragment>::@setter::y
    synthetic static set z=
      reference: <none>
      parameters
        requiredPositional _z
          reference: <none>
          type: List<String>
      firstFragment: <testLibraryFragment>::@setter::z
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            p @16
              reference: <testLibraryFragment>::@class::C::@field::p
              enclosingElement: <testLibraryFragment>::@class::C
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic get p @-1
              reference: <testLibraryFragment>::@class::C::@getter::p
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set p= @-1
              reference: <testLibraryFragment>::@class::C::@setter::p
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _p @-1
                  type: int
              returnType: void
      topLevelVariables
        static x @25
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: List<C>
          shouldUseTypeForInitializerInference: false
        static y @40
          reference: <testLibraryFragment>::@topLevelVariable::y
          enclosingElement: <testLibraryFragment>
          type: Iterable<int>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: List<C>
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: List<C>
          returnType: void
        synthetic static get y @-1
          reference: <testLibraryFragment>::@getter::y
          enclosingElement: <testLibraryFragment>
          returnType: Iterable<int>
        synthetic static set y= @-1
          reference: <testLibraryFragment>::@setter::y
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C
          fields
            p @16
              reference: <testLibraryFragment>::@class::C::@field::p
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::p
              setter2: <testLibraryFragment>::@class::C::@setter::p
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get p @-1
              reference: <testLibraryFragment>::@class::C::@getter::p
              element: <none>
          setters
            set p= @-1
              reference: <testLibraryFragment>::@class::C::@setter::p
              element: <none>
              parameters
                _p @-1
                  element: <none>
      topLevelVariables
        x @25
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
        y @40
          reference: <testLibraryFragment>::@topLevelVariable::y
          element: <none>
          getter2: <testLibraryFragment>::@getter::y
          setter2: <testLibraryFragment>::@setter::y
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
        get y @-1
          reference: <testLibraryFragment>::@getter::y
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
        set y= @-1
          reference: <testLibraryFragment>::@setter::y
          element: <none>
          parameters
            _y @-1
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        p
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::p
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get p
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::p
      setters
        synthetic set p=
          reference: <none>
          parameters
            requiredPositional _p
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::C::@setter::p
  topLevelVariables
    x
      reference: <none>
      type: List<C>
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
    y
      reference: <none>
      type: Iterable<int>
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
    synthetic static get y
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::y
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: List<C>
      firstFragment: <testLibraryFragment>::@setter::x
    synthetic static set y=
      reference: <none>
      parameters
        requiredPositional _y
          reference: <none>
          type: Iterable<int>
      firstFragment: <testLibraryFragment>::@setter::y
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
      enclosingElement: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          typeParameters
            U @2
              element: <none>
            V @5
              element: <none>
  functions
    f
      reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant U @8
              defaultType: dynamic
            covariant V @11
              defaultType: dynamic
          fields
            final x @24
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement: <testLibraryFragment>::@class::C
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            U @8
              element: <none>
            V @11
              element: <none>
          fields
            x @24
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::x
          constructors
            new @29
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        U
        V
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final x
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          getter: <none>
      constructors
        new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get x
          reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant U @8
              defaultType: dynamic
            covariant V @11
              defaultType: dynamic
          fields
            synthetic x @-1
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            get x @22
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement: <testLibraryFragment>::@class::C
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            U @8
              element: <none>
            V @11
              element: <none>
          fields
            x @-1
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::x
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get x @22
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        U
        V
      firstFragment: <testLibraryFragment>::@class::C
      fields
        synthetic x
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        get x
          reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            f @15
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement: <testLibraryFragment>::@class::C
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @8
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          methods
            f @15
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <none>
              typeParameters
                U @17
                  element: <none>
                V @20
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          reference: <none>
          typeParameters
            U
            V
          firstFragment: <testLibraryFragment>::@class::C::@method::f
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant U @8
              defaultType: dynamic
            covariant V @11
              defaultType: dynamic
          fields
            synthetic x @-1
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            set x= @27
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional value @29
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            U @8
              element: <none>
            V @11
              element: <none>
          fields
            x @-1
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <none>
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          setters
            set x= @27
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <none>
              parameters
                value @29
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        U
        V
      firstFragment: <testLibraryFragment>::@class::C
      fields
        synthetic x
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      setters
        set x=
          reference: <none>
          parameters
            requiredPositional value
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
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
      enclosingElement: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          typeParameters
            T @2
              element: <none>
  functions
    f
      reference: <none>
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
      enclosingElement: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          typeParameters
            T @2
              element: <none>
  functions
    f
      reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant P @8
              bound: num
              defaultType: num
          constructors
            factory @35
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional p @49
                  type: Iterable<P>
            _ @66
              reference: <testLibraryFragment>::@class::C::@constructor::_
              enclosingElement: <testLibraryFragment>::@class::C
              periodOffset: 65
              nameEnd: 67
      topLevelVariables
        static c @78
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C<dynamic>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C<dynamic>
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C<dynamic>
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            P @8
              element: <none>
          constructors
            factory new @35
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              parameters
                p @49
                  element: <none>
            _ @66
              reference: <testLibraryFragment>::@class::C::@constructor::_
              element: <none>
              periodOffset: 65
              nameEnd: 67
      topLevelVariables
        c @78
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        P
          bound: num
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        factory new
          reference: <none>
          parameters
            requiredPositional p
              reference: <none>
              type: Iterable<P>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
        _
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::_
  topLevelVariables
    c
      reference: <none>
      type: C<dynamic>
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C<dynamic>
      firstFragment: <testLibraryFragment>::@setter::c
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            static final foo @25
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement: <testLibraryFragment>::@class::A
              type: int
              shouldUseTypeForInitializerInference: false
            static final bar @56
              reference: <testLibraryFragment>::@class::A::@field::bar
              enclosingElement: <testLibraryFragment>::@class::A
              type: int Function(double)
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: int
            synthetic static get bar @-1
              reference: <testLibraryFragment>::@class::A::@getter::bar
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: int Function(double)
          methods
            static baz @100
              reference: <testLibraryFragment>::@class::A::@method::baz
              enclosingElement: <testLibraryFragment>::@class::A
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
          element: <testLibraryFragment>::@class::A
          fields
            foo @25
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::foo
            bar @56
              reference: <testLibraryFragment>::@class::A::@field::bar
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::bar
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <none>
            get bar @-1
              reference: <testLibraryFragment>::@class::A::@getter::bar
              element: <none>
          methods
            baz @100
              reference: <testLibraryFragment>::@class::A::@method::baz
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static final foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          getter: <none>
        static final bar
          reference: <none>
          type: int Function(double)
          firstFragment: <testLibraryFragment>::@class::A::@field::bar
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
        synthetic static get bar
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::bar
      methods
        static baz
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@method::baz
''');
  }

  test_inferred_type_inference_failure_on_function_invocation() async {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        strictInference: true,
      ),
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: int
          returnType: void
      functions
        m @4
          reference: <testLibraryFragment>::@function::m
          enclosingElement: <testLibraryFragment>
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
        x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
      functions
        m @4
          reference: <testLibraryFragment>::@function::m
          element: <none>
          typeParameters
            T @6
              element: <none>
  topLevelVariables
    x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::x
  functions
    m
      reference: <none>
      typeParameters
        T
      returnType: int
''');
  }

  test_inferred_type_inference_failure_on_generic_invocation() async {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        strictInference: true,
      ),
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static m @19
          reference: <testLibraryFragment>::@topLevelVariable::m
          enclosingElement: <testLibraryFragment>
          type: int Function<T>()?
          shouldUseTypeForInitializerInference: true
        static n @53
          reference: <testLibraryFragment>::@topLevelVariable::n
          enclosingElement: <testLibraryFragment>
          type: int Function<T>()
          shouldUseTypeForInitializerInference: true
        static x @73
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get m @-1
          reference: <testLibraryFragment>::@getter::m
          enclosingElement: <testLibraryFragment>
          returnType: int Function<T>()?
        synthetic static set m= @-1
          reference: <testLibraryFragment>::@setter::m
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _m @-1
              type: int Function<T>()?
          returnType: void
        synthetic static get n @-1
          reference: <testLibraryFragment>::@getter::n
          enclosingElement: <testLibraryFragment>
          returnType: int Function<T>()
        synthetic static set n= @-1
          reference: <testLibraryFragment>::@setter::n
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _n @-1
              type: int Function<T>()
          returnType: void
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
        m @19
          reference: <testLibraryFragment>::@topLevelVariable::m
          element: <none>
          getter2: <testLibraryFragment>::@getter::m
          setter2: <testLibraryFragment>::@setter::m
        n @53
          reference: <testLibraryFragment>::@topLevelVariable::n
          element: <none>
          getter2: <testLibraryFragment>::@getter::n
          setter2: <testLibraryFragment>::@setter::n
        x @73
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get m @-1
          reference: <testLibraryFragment>::@getter::m
          element: <none>
        get n @-1
          reference: <testLibraryFragment>::@getter::n
          element: <none>
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set m= @-1
          reference: <testLibraryFragment>::@setter::m
          element: <none>
          parameters
            _m @-1
              element: <none>
        set n= @-1
          reference: <testLibraryFragment>::@setter::n
          element: <none>
          parameters
            _n @-1
              element: <none>
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    m
      reference: <none>
      type: int Function<T>()?
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      getter: <none>
      setter: <none>
    n
      reference: <none>
      type: int Function<T>()
      firstFragment: <testLibraryFragment>::@topLevelVariable::n
      getter: <none>
      setter: <none>
    x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get m
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::m
    synthetic static get n
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::n
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set m=
      reference: <none>
      parameters
        requiredPositional _m
          reference: <none>
          type: int Function<T>()?
      firstFragment: <testLibraryFragment>::@setter::m
    synthetic static set n=
      reference: <none>
      parameters
        requiredPositional _n
          reference: <none>
          type: int Function<T>()
      firstFragment: <testLibraryFragment>::@setter::n
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::x
''');
  }

  test_inferred_type_inference_failure_on_instance_creation() async {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        strictInference: true,
      ),
    );
    var library = await buildLibrary(r'''
import 'dart:collection';
var m = HashMap();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:collection
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:collection
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static m @30
          reference: <testLibraryFragment>::@topLevelVariable::m
          enclosingElement: <testLibraryFragment>
          type: HashMap<dynamic, dynamic>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get m @-1
          reference: <testLibraryFragment>::@getter::m
          enclosingElement: <testLibraryFragment>
          returnType: HashMap<dynamic, dynamic>
        synthetic static set m= @-1
          reference: <testLibraryFragment>::@setter::m
          enclosingElement: <testLibraryFragment>
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
        m @30
          reference: <testLibraryFragment>::@topLevelVariable::m
          element: <none>
          getter2: <testLibraryFragment>::@getter::m
          setter2: <testLibraryFragment>::@setter::m
      getters
        get m @-1
          reference: <testLibraryFragment>::@getter::m
          element: <none>
      setters
        set m= @-1
          reference: <testLibraryFragment>::@setter::m
          element: <none>
          parameters
            _m @-1
              element: <none>
  topLevelVariables
    m
      reference: <none>
      type: HashMap<dynamic, dynamic>
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      getter: <none>
      setter: <none>
  getters
    synthetic static get m
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::m
  setters
    synthetic static set m=
      reference: <none>
      parameters
        requiredPositional _m
          reference: <none>
          type: HashMap<dynamic, dynamic>
      firstFragment: <testLibraryFragment>::@setter::m
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static c @34
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static d @49
          reference: <testLibraryFragment>::@topLevelVariable::d
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static set a= @-1
          reference: <testLibraryFragment>::@setter::a
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _a @-1
              type: dynamic
          returnType: void
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static set b= @-1
          reference: <testLibraryFragment>::@setter::b
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _b @-1
              type: dynamic
          returnType: void
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: dynamic
          returnType: void
        synthetic static get d @-1
          reference: <testLibraryFragment>::@getter::d
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set d= @-1
          reference: <testLibraryFragment>::@setter::d
          enclosingElement: <testLibraryFragment>
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
        a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
          setter2: <testLibraryFragment>::@setter::a
        b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
          setter2: <testLibraryFragment>::@setter::b
        c @34
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        d @49
          reference: <testLibraryFragment>::@topLevelVariable::d
          element: <none>
          getter2: <testLibraryFragment>::@getter::d
          setter2: <testLibraryFragment>::@setter::d
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get d @-1
          reference: <testLibraryFragment>::@getter::d
          element: <none>
      setters
        set a= @-1
          reference: <testLibraryFragment>::@setter::a
          element: <none>
          parameters
            _a @-1
              element: <none>
        set b= @-1
          reference: <testLibraryFragment>::@setter::b
          element: <none>
          parameters
            _b @-1
              element: <none>
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set d= @-1
          reference: <testLibraryFragment>::@setter::d
          element: <none>
          parameters
            _d @-1
              element: <none>
  topLevelVariables
    a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
      setter: <none>
    b
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
      setter: <none>
    c
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
    d
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::d
      getter: <none>
      setter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get d
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::d
  setters
    synthetic static set a=
      reference: <none>
      parameters
        requiredPositional _a
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::a
    synthetic static set b=
      reference: <none>
      parameters
        requiredPositional _b
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::b
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::c
    synthetic static set d=
      reference: <none>
      parameters
        requiredPositional _d
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::d
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
      enclosingElement: <testLibrary>
      classes
        class C @31
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          supertype: D
          fields
            v @49
              reference: <testLibraryFragment>::@class::C::@field::v
              enclosingElement: <testLibraryFragment>::@class::C
              type: int Function(String)
                alias: <testLibraryFragment>::@typeAlias::F
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          accessors
            synthetic get v @-1
              reference: <testLibraryFragment>::@class::C::@getter::v
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int Function(String)
                alias: <testLibraryFragment>::@typeAlias::F
            synthetic set v= @-1
              reference: <testLibraryFragment>::@class::C::@setter::v
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _v @-1
                  type: int Function(String)
                    alias: <testLibraryFragment>::@typeAlias::F
              returnType: void
        abstract class D @69
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          fields
            synthetic v @-1
              reference: <testLibraryFragment>::@class::D::@field::v
              enclosingElement: <testLibraryFragment>::@class::D
              type: int Function(String)
                alias: <testLibraryFragment>::@typeAlias::F
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
          accessors
            abstract get v @79
              reference: <testLibraryFragment>::@class::D::@getter::v
              enclosingElement: <testLibraryFragment>::@class::D
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
          element: <testLibraryFragment>::@class::C
          fields
            v @49
              reference: <testLibraryFragment>::@class::C::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::v
              setter2: <testLibraryFragment>::@class::C::@setter::v
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          getters
            get v @-1
              reference: <testLibraryFragment>::@class::C::@getter::v
              element: <none>
          setters
            set v= @-1
              reference: <testLibraryFragment>::@class::C::@setter::v
              element: <none>
              parameters
                _v @-1
                  element: <none>
        class D @69
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          fields
            v @-1
              reference: <testLibraryFragment>::@class::D::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@class::D::@getter::v
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
          getters
            get v @79
              reference: <testLibraryFragment>::@class::D::@getter::v
              element: <none>
      typeAliases
        F @12
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      fields
        v
          reference: <none>
          type: int Function(String)
            alias: <testLibraryFragment>::@typeAlias::F
          firstFragment: <testLibraryFragment>::@class::C::@field::v
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::v
      setters
        synthetic set v=
          reference: <none>
          parameters
            requiredPositional _v
              reference: <none>
              type: int Function(String)
                alias: <testLibraryFragment>::@typeAlias::F
          firstFragment: <testLibraryFragment>::@class::C::@setter::v
    abstract class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      fields
        synthetic v
          reference: <none>
          type: int Function(String)
            alias: <testLibraryFragment>::@typeAlias::F
          firstFragment: <testLibraryFragment>::@class::D::@field::v
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      getters
        abstract get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@getter::v
  typeAliases
    F
      reference: <none>
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
        x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::x
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int?
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int?
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
        x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    x
      reference: <none>
      type: int?
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: int?
      firstFragment: <testLibraryFragment>::@setter::x
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: void Function()
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: void Function()
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
        x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    x
      reference: <none>
      type: void Function()
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: void Function()
      firstFragment: <testLibraryFragment>::@setter::x
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: void Function()?
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: void Function()?
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
        x @21
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    x
      reference: <none>
      type: void Function()?
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: void Function()?
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          supertype: D<int, T>
          fields
            v @37
              reference: <testLibraryFragment>::@class::C::@field::v
              enclosingElement: <testLibraryFragment>::@class::C
              type: Map<T, int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::D::@constructor::new
                substitution: {U: int, V: T}
          accessors
            synthetic get v @-1
              reference: <testLibraryFragment>::@class::C::@getter::v
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: Map<T, int>
            synthetic set v= @-1
              reference: <testLibraryFragment>::@class::C::@setter::v
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _v @-1
                  type: Map<T, int>
              returnType: void
        abstract class D @57
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant U @59
              defaultType: dynamic
            covariant V @62
              defaultType: dynamic
          fields
            synthetic v @-1
              reference: <testLibraryFragment>::@class::D::@field::v
              enclosingElement: <testLibraryFragment>::@class::D
              type: Map<V, U>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
          accessors
            abstract get v @83
              reference: <testLibraryFragment>::@class::D::@getter::v
              enclosingElement: <testLibraryFragment>::@class::D
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @8
              element: <none>
          fields
            v @37
              reference: <testLibraryFragment>::@class::C::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::v
              setter2: <testLibraryFragment>::@class::C::@setter::v
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::D::@constructor::new
                substitution: {U: int, V: T}
          getters
            get v @-1
              reference: <testLibraryFragment>::@class::C::@getter::v
              element: <none>
          setters
            set v= @-1
              reference: <testLibraryFragment>::@class::C::@setter::v
              element: <none>
              parameters
                _v @-1
                  element: <none>
        class D @57
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          typeParameters
            U @59
              element: <none>
            V @62
              element: <none>
          fields
            v @-1
              reference: <testLibraryFragment>::@class::D::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@class::D::@getter::v
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
          getters
            get v @83
              reference: <testLibraryFragment>::@class::D::@getter::v
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D<int, T>
      fields
        v
          reference: <none>
          type: Map<T, int>
          firstFragment: <testLibraryFragment>::@class::C::@field::v
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::v
      setters
        synthetic set v=
          reference: <none>
          parameters
            requiredPositional _v
              reference: <none>
              type: Map<T, int>
          firstFragment: <testLibraryFragment>::@class::C::@setter::v
    abstract class D
      reference: <testLibraryFragment>::@class::D
      typeParameters
        U
        V
      firstFragment: <testLibraryFragment>::@class::D
      fields
        synthetic v
          reference: <none>
          type: Map<V, U>
          firstFragment: <testLibraryFragment>::@class::D::@field::v
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      getters
        abstract get v
          reference: <none>
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
      enclosingElement: <testLibrary>
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
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: dynamic
          returnType: void
      functions
        h @33
          reference: <testLibraryFragment>::@function::h
          enclosingElement: <testLibraryFragment>
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
          element: <none>
      topLevelVariables
        v @53
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <none>
          parameters
            _v @-1
              element: <none>
      functions
        h @33
          reference: <testLibraryFragment>::@function::h
          element: <none>
          parameters
            f @37
              element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: void Function(int Function(String))
  topLevelVariables
    v
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      reference: <none>
      parameters
        requiredPositional _v
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::v
  functions
    h
      reference: <none>
      parameters
        requiredPositional f
          reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
            covariant U @11
              defaultType: dynamic
          supertype: D<U, int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::D::@constructor::new
                substitution: {V: U, W: int}
          methods
            f @41
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional x @47
                  type: int
                requiredPositional g @50
                  type: int Function(U)
              returnType: void
        abstract class D @73
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant V @75
              defaultType: dynamic
            covariant W @78
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
          methods
            abstract f @90
              reference: <testLibraryFragment>::@class::D::@method::f
              enclosingElement: <testLibraryFragment>::@class::D
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @8
              element: <none>
            U @11
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::D::@constructor::new
                substitution: {V: U, W: int}
          methods
            f @41
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <none>
              parameters
                x @47
                  element: <none>
                g @50
                  element: <none>
        class D @73
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          typeParameters
            V @75
              element: <none>
            W @78
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
          methods
            f @90
              reference: <testLibraryFragment>::@class::D::@method::f
              element: <none>
              parameters
                x @96
                  element: <none>
                g @101
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
        U
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D<U, int>
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          reference: <none>
          parameters
            requiredPositional x
              reference: <none>
              type: int
            requiredPositional g
              reference: <none>
              type: int Function(U)
          firstFragment: <testLibraryFragment>::@class::C::@method::f
    abstract class D
      reference: <testLibraryFragment>::@class::D
      typeParameters
        V
        W
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      methods
        abstract f
          reference: <none>
          parameters
            requiredPositional x
              reference: <none>
              type: int
            requiredPositional g
              reference: <none>
              type: W Function(V)
              parameters
                requiredPositional s
                  reference: <none>
                  type: V
          firstFragment: <testLibraryFragment>::@class::D::@method::f
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @23
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          supertype: D
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              superConstructor: package:test/a.dart::<fragment>::@class::D::@constructor::new
          methods
            f @44
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional x @50
                  type: int
                requiredPositional g @53
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
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              superConstructor: package:test/a.dart::<fragment>::@class::D::@constructor::new
          methods
            f @44
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <none>
              parameters
                x @50
                  element: <none>
                g @53
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          reference: <none>
          parameters
            requiredPositional x
              reference: <none>
              type: int
            requiredPositional g
              reference: <none>
              type: int Function(String)
          firstFragment: <testLibraryFragment>::@class::C::@method::f
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          supertype: D
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          methods
            f @25
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional x @31
                  type: int
                requiredPositional g @34
                  type: int Function(String)
              returnType: void
        abstract class D @57
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
          methods
            abstract f @66
              reference: <testLibraryFragment>::@class::D::@method::f
              enclosingElement: <testLibraryFragment>::@class::D
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
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          methods
            f @25
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <none>
              parameters
                x @31
                  element: <none>
                g @34
                  element: <none>
        class D @57
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
          methods
            f @66
              reference: <testLibraryFragment>::@class::D::@method::f
              element: <none>
              parameters
                x @72
                  element: <none>
                g @79
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          reference: <none>
          parameters
            requiredPositional x
              reference: <none>
              type: int
            requiredPositional g
              reference: <none>
              type: int Function(String)
          firstFragment: <testLibraryFragment>::@class::C::@method::f
    abstract class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      methods
        abstract f
          reference: <none>
          parameters
            requiredPositional x
              reference: <none>
              type: int
            requiredPositional g
              reference: <none>
              type: int Function(String)
              parameters
                requiredPositional s
                  reference: <none>
                  type: String
          firstFragment: <testLibraryFragment>::@class::D::@method::f
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static v @40
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: dynamic
          returnType: void
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
        v @40
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <none>
          parameters
            _v @-1
              element: <none>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            g @7
              element: <none>
  topLevelVariables
    v
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      reference: <none>
      parameters
        requiredPositional _v
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::v
  functions
    f
      reference: <none>
      parameters
        requiredPositional g
          reference: <none>
          type: void Function(int, void Function())
          parameters
            requiredPositional x
              reference: <none>
              type: int
            requiredPositional h
              reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static v @42
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: dynamic
          returnType: void
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
        v @42
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <none>
          parameters
            _v @-1
              element: <none>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            default g @8
              reference: <testLibraryFragment>::@function::f::@parameter::g
              element: <none>
  topLevelVariables
    v
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      reference: <none>
      parameters
        requiredPositional _v
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::v
  functions
    f
      reference: <none>
      parameters
        optionalNamed g
          reference: <none>
          type: void Function(int, void Function())
          parameters
            requiredPositional x
              reference: <none>
              type: int
            requiredPositional h
              reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          supertype: D
          fields
            synthetic f @-1
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement: <testLibraryFragment>::@class::C
              type: int Function(String)
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          accessors
            set f= @29
              reference: <testLibraryFragment>::@class::C::@setter::f
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional g @31
                  type: int Function(String)
              returnType: void
        abstract class D @54
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          fields
            synthetic f @-1
              reference: <testLibraryFragment>::@class::D::@field::f
              enclosingElement: <testLibraryFragment>::@class::D
              type: int Function(String)
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
          accessors
            abstract set f= @67
              reference: <testLibraryFragment>::@class::D::@setter::f
              enclosingElement: <testLibraryFragment>::@class::D
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
          element: <testLibraryFragment>::@class::C
          fields
            f @-1
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <none>
              setter2: <testLibraryFragment>::@class::C::@setter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          setters
            set f= @29
              reference: <testLibraryFragment>::@class::C::@setter::f
              element: <none>
              parameters
                g @31
                  element: <none>
        class D @54
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          fields
            f @-1
              reference: <testLibraryFragment>::@class::D::@field::f
              element: <none>
              setter2: <testLibraryFragment>::@class::D::@setter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
          setters
            set f= @67
              reference: <testLibraryFragment>::@class::D::@setter::f
              element: <none>
              parameters
                g @73
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      fields
        synthetic f
          reference: <none>
          type: int Function(String)
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      setters
        set f=
          reference: <none>
          parameters
            requiredPositional g
              reference: <none>
              type: int Function(String)
          firstFragment: <testLibraryFragment>::@class::C::@setter::f
    abstract class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      fields
        synthetic f
          reference: <none>
          type: int Function(String)
          firstFragment: <testLibraryFragment>::@class::D::@field::f
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      setters
        abstract set f=
          reference: <none>
          parameters
            requiredPositional g
              reference: <none>
              type: int Function(String)
              parameters
                requiredPositional s
                  reference: <none>
                  type: String
          firstFragment: <testLibraryFragment>::@class::D::@setter::f
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class B @23
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: package:test/a.dart::<fragment>::@class::A::@constructor::new
          methods
            m @39
              reference: <testLibraryFragment>::@class::B::@method::m
              enclosingElement: <testLibraryFragment>::@class::B
              parameters
                requiredPositional p @41
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
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
              superConstructor: package:test/a.dart::<fragment>::@class::A::@constructor::new
          methods
            m @39
              reference: <testLibraryFragment>::@class::B::@method::m
              element: <none>
              parameters
                p @41
                  element: <none>
  classes
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      methods
        m
          reference: <none>
          parameters
            requiredPositional p
              reference: <none>
              type: Stream<dynamic>
          firstFragment: <testLibraryFragment>::@class::B::@method::m
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            @12
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
            named @21
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::A
              periodOffset: 20
              nameEnd: 26
      topLevelVariables
        static a1 @36
          reference: <testLibraryFragment>::@topLevelVariable::a1
          enclosingElement: <testLibraryFragment>
          type: A
          shouldUseTypeForInitializerInference: false
        static a2 @50
          reference: <testLibraryFragment>::@topLevelVariable::a2
          enclosingElement: <testLibraryFragment>
          type: A
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a1 @-1
          reference: <testLibraryFragment>::@getter::a1
          enclosingElement: <testLibraryFragment>
          returnType: A
        synthetic static set a1= @-1
          reference: <testLibraryFragment>::@setter::a1
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _a1 @-1
              type: A
          returnType: void
        synthetic static get a2 @-1
          reference: <testLibraryFragment>::@getter::a2
          enclosingElement: <testLibraryFragment>
          returnType: A
        synthetic static set a2= @-1
          reference: <testLibraryFragment>::@setter::a2
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A
          constructors
            new @12
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
            named @21
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <none>
              periodOffset: 20
              nameEnd: 26
      topLevelVariables
        a1 @36
          reference: <testLibraryFragment>::@topLevelVariable::a1
          element: <none>
          getter2: <testLibraryFragment>::@getter::a1
          setter2: <testLibraryFragment>::@setter::a1
        a2 @50
          reference: <testLibraryFragment>::@topLevelVariable::a2
          element: <none>
          getter2: <testLibraryFragment>::@getter::a2
          setter2: <testLibraryFragment>::@setter::a2
      getters
        get a1 @-1
          reference: <testLibraryFragment>::@getter::a1
          element: <none>
        get a2 @-1
          reference: <testLibraryFragment>::@getter::a2
          element: <none>
      setters
        set a1= @-1
          reference: <testLibraryFragment>::@setter::a1
          element: <none>
          parameters
            _a1 @-1
              element: <none>
        set a2= @-1
          reference: <testLibraryFragment>::@setter::a2
          element: <none>
          parameters
            _a2 @-1
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
        named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
  topLevelVariables
    a1
      reference: <none>
      type: A
      firstFragment: <testLibraryFragment>::@topLevelVariable::a1
      getter: <none>
      setter: <none>
    a2
      reference: <none>
      type: A
      firstFragment: <testLibraryFragment>::@topLevelVariable::a2
      getter: <none>
      setter: <none>
  getters
    synthetic static get a1
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a1
    synthetic static get a2
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a2
  setters
    synthetic static set a1=
      reference: <none>
      parameters
        requiredPositional _a1
          reference: <none>
          type: A
      firstFragment: <testLibraryFragment>::@setter::a1
    synthetic static set a2=
      reference: <none>
      parameters
        requiredPositional _a2
          reference: <none>
          type: A
      firstFragment: <testLibraryFragment>::@setter::a2
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
  libraryImports
    package:test/foo.dart as foo @21
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    foo @21
      reference: <testLibraryFragment>::@prefix::foo
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo.dart as foo @21
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        foo @21
          reference: <testLibraryFragment>::@prefix::foo
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static a1 @30
          reference: <testLibraryFragment>::@topLevelVariable::a1
          enclosingElement: <testLibraryFragment>
          type: A
          shouldUseTypeForInitializerInference: false
        static a2 @48
          reference: <testLibraryFragment>::@topLevelVariable::a2
          enclosingElement: <testLibraryFragment>
          type: A
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a1 @-1
          reference: <testLibraryFragment>::@getter::a1
          enclosingElement: <testLibraryFragment>
          returnType: A
        synthetic static set a1= @-1
          reference: <testLibraryFragment>::@setter::a1
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _a1 @-1
              type: A
          returnType: void
        synthetic static get a2 @-1
          reference: <testLibraryFragment>::@getter::a2
          enclosingElement: <testLibraryFragment>
          returnType: A
        synthetic static set a2= @-1
          reference: <testLibraryFragment>::@setter::a2
          enclosingElement: <testLibraryFragment>
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
        package:test/foo.dart
      prefixes
        foo
          reference: <testLibraryFragment>::@prefix::foo
      topLevelVariables
        a1 @30
          reference: <testLibraryFragment>::@topLevelVariable::a1
          element: <none>
          getter2: <testLibraryFragment>::@getter::a1
          setter2: <testLibraryFragment>::@setter::a1
        a2 @48
          reference: <testLibraryFragment>::@topLevelVariable::a2
          element: <none>
          getter2: <testLibraryFragment>::@getter::a2
          setter2: <testLibraryFragment>::@setter::a2
      getters
        get a1 @-1
          reference: <testLibraryFragment>::@getter::a1
          element: <none>
        get a2 @-1
          reference: <testLibraryFragment>::@getter::a2
          element: <none>
      setters
        set a1= @-1
          reference: <testLibraryFragment>::@setter::a1
          element: <none>
          parameters
            _a1 @-1
              element: <none>
        set a2= @-1
          reference: <testLibraryFragment>::@setter::a2
          element: <none>
          parameters
            _a2 @-1
              element: <none>
  topLevelVariables
    a1
      reference: <none>
      type: A
      firstFragment: <testLibraryFragment>::@topLevelVariable::a1
      getter: <none>
      setter: <none>
    a2
      reference: <none>
      type: A
      firstFragment: <testLibraryFragment>::@topLevelVariable::a2
      getter: <none>
      setter: <none>
  getters
    synthetic static get a1
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a1
    synthetic static get a2
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a2
  setters
    synthetic static set a1=
      reference: <none>
      parameters
        requiredPositional _a1
          reference: <none>
          type: A
      firstFragment: <testLibraryFragment>::@setter::a1
    synthetic static set a2=
      reference: <none>
      parameters
        requiredPositional _a2
          reference: <none>
          type: A
      firstFragment: <testLibraryFragment>::@setter::a2
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static v @71
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: List<Object Function(int Function(String))>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: List<Object Function(int Function(String))>
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: List<Object Function(int Function(String))>
          returnType: void
      functions
        f @4
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional x @10
              type: int Function(String)
              parameters
                requiredPositional y @19
                  type: String
          returnType: int
        g @39
          reference: <testLibraryFragment>::@function::g
          enclosingElement: <testLibraryFragment>
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
        v @71
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <none>
          parameters
            _v @-1
              element: <none>
      functions
        f @4
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            x @10
              element: <none>
        g @39
          reference: <testLibraryFragment>::@function::g
          element: <none>
          parameters
            x @45
              element: <none>
  topLevelVariables
    v
      reference: <none>
      type: List<Object Function(int Function(String))>
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      reference: <none>
      parameters
        requiredPositional _v
          reference: <none>
          type: List<Object Function(int Function(String))>
      firstFragment: <testLibraryFragment>::@setter::v
  functions
    f
      reference: <none>
      parameters
        requiredPositional x
          reference: <none>
          type: int Function(String)
          parameters
            requiredPositional y
              reference: <none>
              type: String
      returnType: int
    g
      reference: <none>
      parameters
        requiredPositional x
          reference: <none>
          type: int Function(String)
          parameters
            requiredPositional y
              reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        abstract class A @15
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          methods
            abstract m @25
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: int
        abstract class B @48
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
          methods
            abstract m @61
              reference: <testLibraryFragment>::@class::B::@method::m
              enclosingElement: <testLibraryFragment>::@class::B
              returnType: String
        abstract class C @84
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          interfaces
            A
            B
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
        abstract class D @121
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          supertype: C
          fields
            f @141
              reference: <testLibraryFragment>::@class::D::@field::f
              enclosingElement: <testLibraryFragment>::@class::D
              type: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
              superConstructor: <testLibraryFragment>::@class::C::@constructor::new
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::D::@getter::f
              enclosingElement: <testLibraryFragment>::@class::D
              returnType: dynamic
            synthetic set f= @-1
              reference: <testLibraryFragment>::@class::D::@setter::f
              enclosingElement: <testLibraryFragment>::@class::D
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
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          methods
            m @25
              reference: <testLibraryFragment>::@class::A::@method::m
              element: <none>
        class B @48
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
          methods
            m @61
              reference: <testLibraryFragment>::@class::B::@method::m
              element: <none>
        class C @84
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
        class D @121
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          fields
            f @141
              reference: <testLibraryFragment>::@class::D::@field::f
              element: <none>
              getter2: <testLibraryFragment>::@class::D::@getter::f
              setter2: <testLibraryFragment>::@class::D::@setter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
              superConstructor: <testLibraryFragment>::@class::C::@constructor::new
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::D::@getter::f
              element: <none>
          setters
            set f= @-1
              reference: <testLibraryFragment>::@class::D::@setter::f
              element: <none>
              parameters
                _f @-1
                  element: <none>
  classes
    abstract class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        abstract m
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@method::m
    abstract class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      methods
        abstract m
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@method::m
    abstract class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    abstract class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      supertype: C
      fields
        f
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::D::@field::f
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      getters
        synthetic get f
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@getter::f
      setters
        synthetic set f=
          reference: <none>
          parameters
            requiredPositional _f
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@class::D::@setter::f
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          methods
            call @19
              reference: <testLibraryFragment>::@class::A::@method::call
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: double
        class B @42
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          fields
            a @50
              reference: <testLibraryFragment>::@class::B::@field::a
              enclosingElement: <testLibraryFragment>::@class::B
              type: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
          accessors
            synthetic get a @-1
              reference: <testLibraryFragment>::@class::B::@getter::a
              enclosingElement: <testLibraryFragment>::@class::B
              returnType: A
            synthetic set a= @-1
              reference: <testLibraryFragment>::@class::B::@setter::a
              enclosingElement: <testLibraryFragment>::@class::B
              parameters
                requiredPositional _a @-1
                  type: A
              returnType: void
      topLevelVariables
        static c @59
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: double
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: double
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          methods
            call @19
              reference: <testLibraryFragment>::@class::A::@method::call
              element: <none>
        class B @42
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          fields
            a @50
              reference: <testLibraryFragment>::@class::B::@field::a
              element: <none>
              getter2: <testLibraryFragment>::@class::B::@getter::a
              setter2: <testLibraryFragment>::@class::B::@setter::a
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
          getters
            get a @-1
              reference: <testLibraryFragment>::@class::B::@getter::a
              element: <none>
          setters
            set a= @-1
              reference: <testLibraryFragment>::@class::B::@setter::a
              element: <none>
              parameters
                _a @-1
                  element: <none>
      topLevelVariables
        c @59
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        call
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@method::call
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        a
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@class::B::@field::a
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      getters
        synthetic get a
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@getter::a
      setters
        synthetic set a=
          reference: <none>
          parameters
            requiredPositional _a
              reference: <none>
              type: A
          firstFragment: <testLibraryFragment>::@class::B::@setter::a
  topLevelVariables
    c
      reference: <none>
      type: double
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: double
      firstFragment: <testLibraryFragment>::@setter::c
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int Function()
          shouldUseTypeForInitializerInference: false
        static b @42
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int Function()
        synthetic static set a= @-1
          reference: <testLibraryFragment>::@setter::a
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _a @-1
              type: int Function()
          returnType: void
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set b= @-1
          reference: <testLibraryFragment>::@setter::b
          enclosingElement: <testLibraryFragment>
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
        a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
          setter2: <testLibraryFragment>::@setter::a
        b @42
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
          setter2: <testLibraryFragment>::@setter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
      setters
        set a= @-1
          reference: <testLibraryFragment>::@setter::a
          element: <none>
          parameters
            _a @-1
              element: <none>
        set b= @-1
          reference: <testLibraryFragment>::@setter::b
          element: <none>
          parameters
            _b @-1
              element: <none>
  topLevelVariables
    a
      reference: <none>
      type: int Function()
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
      setter: <none>
    b
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
      setter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
  setters
    synthetic static set a=
      reference: <none>
      parameters
        requiredPositional _a
          reference: <none>
          type: int Function()
      firstFragment: <testLibraryFragment>::@setter::a
    synthetic static set b=
      reference: <none>
      parameters
        requiredPositional _b
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::b
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
  libraryImports
    package:test/a.dart deferred as a @28
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    a @28
      reference: <testLibraryFragment>::@prefix::a
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart deferred as a @28
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        a @28
          reference: <testLibraryFragment>::@prefix::a
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static x @35
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: Future<dynamic> Function()
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: Future<dynamic> Function()
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
        package:test/a.dart
      prefixes
        a
          reference: <testLibraryFragment>::@prefix::a
      topLevelVariables
        x @35
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    x
      reference: <none>
      type: Future<dynamic> Function()
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: Future<dynamic> Function()
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int Function(int Function(String))
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int Function(int Function(String))
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
        x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    x
      reference: <none>
      type: int Function(int Function(String))
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: int Function(int Function(String))
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int Function(int Function(String))
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int Function(int Function(String))
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
        x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    x
      reference: <none>
      type: int Function(int Function(String))
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: int Function(int Function(String))
      firstFragment: <testLibraryFragment>::@setter::x
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static y @21
          reference: <testLibraryFragment>::@topLevelVariable::y
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get y @-1
          reference: <testLibraryFragment>::@getter::y
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set y= @-1
          reference: <testLibraryFragment>::@setter::y
          enclosingElement: <testLibraryFragment>
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
        y @21
          reference: <testLibraryFragment>::@topLevelVariable::y
          element: <none>
          getter2: <testLibraryFragment>::@getter::y
          setter2: <testLibraryFragment>::@setter::y
      getters
        get y @-1
          reference: <testLibraryFragment>::@getter::y
          element: <none>
      setters
        set y= @-1
          reference: <testLibraryFragment>::@setter::y
          element: <none>
          parameters
            _y @-1
              element: <none>
  topLevelVariables
    y
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      getter: <none>
      setter: <none>
  getters
    synthetic static get y
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::y
  setters
    synthetic static set y=
      reference: <none>
      parameters
        requiredPositional _y
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::y
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            static final x @25
              reference: <testLibraryFragment>::@class::A::@field::x
              enclosingElement: <testLibraryFragment>::@class::A
              typeInferenceError: dependencyCycle
                arguments: [x, y]
              type: dynamic
              shouldUseTypeForInitializerInference: false
            static final y @51
              reference: <testLibraryFragment>::@class::A::@field::y
              enclosingElement: <testLibraryFragment>::@class::A
              typeInferenceError: dependencyCycle
                arguments: [x, y]
              type: dynamic
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          accessors
            synthetic static get x @-1
              reference: <testLibraryFragment>::@class::A::@getter::x
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: dynamic
            synthetic static get y @-1
              reference: <testLibraryFragment>::@class::A::@getter::y
              enclosingElement: <testLibraryFragment>::@class::A
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
          element: <testLibraryFragment>::@class::A
          fields
            x @25
              reference: <testLibraryFragment>::@class::A::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::x
            y @51
              reference: <testLibraryFragment>::@class::A::@field::y
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::y
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::A::@getter::x
              element: <none>
            get y @-1
              reference: <testLibraryFragment>::@class::A::@getter::y
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static final x
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::A::@field::x
          getter: <none>
        static final y
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::A::@field::y
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic static get x
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::x
        synthetic static get y
          reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            static final a @25
              reference: <testLibraryFragment>::@class::A::@field::a
              enclosingElement: <testLibraryFragment>::@class::A
              typeInferenceError: dependencyCycle
                arguments: [a, c]
              type: dynamic
              shouldUseTypeForInitializerInference: false
            static final b @49
              reference: <testLibraryFragment>::@class::A::@field::b
              enclosingElement: <testLibraryFragment>::@class::A
              type: A
              shouldUseTypeForInitializerInference: false
            final c @66
              reference: <testLibraryFragment>::@class::A::@field::c
              enclosingElement: <testLibraryFragment>::@class::A
              typeInferenceError: dependencyCycle
                arguments: [a, c]
              type: dynamic
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@class::A::@getter::a
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: dynamic
            synthetic static get b @-1
              reference: <testLibraryFragment>::@class::A::@getter::b
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: A
            synthetic get c @-1
              reference: <testLibraryFragment>::@class::A::@getter::c
              enclosingElement: <testLibraryFragment>::@class::A
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
          element: <testLibraryFragment>::@class::A
          fields
            a @25
              reference: <testLibraryFragment>::@class::A::@field::a
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::a
            b @49
              reference: <testLibraryFragment>::@class::A::@field::b
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::b
            c @66
              reference: <testLibraryFragment>::@class::A::@field::c
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::c
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          getters
            get a @-1
              reference: <testLibraryFragment>::@class::A::@getter::a
              element: <none>
            get b @-1
              reference: <testLibraryFragment>::@class::A::@getter::b
              element: <none>
            get c @-1
              reference: <testLibraryFragment>::@class::A::@getter::c
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        static final a
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::A::@field::a
          getter: <none>
        static final b
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@class::A::@field::b
          getter: <none>
        final c
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::A::@field::c
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::a
        synthetic static get b
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::b
        synthetic get c
          reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            value @17
              reference: <testLibraryFragment>::@class::A::@field::value
              enclosingElement: <testLibraryFragment>::@class::A
              type: T
          constructors
            @27
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional final this.value @34
                  type: T
                  field: <testLibraryFragment>::@class::A::@field::value
          accessors
            synthetic get value @-1
              reference: <testLibraryFragment>::@class::A::@getter::value
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: T
            synthetic set value= @-1
              reference: <testLibraryFragment>::@class::A::@setter::value
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _value @-1
                  type: T
              returnType: void
        class B @51
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          fields
            a @61
              reference: <testLibraryFragment>::@class::B::@field::a
              enclosingElement: <testLibraryFragment>::@class::B
              type: A<String>
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
          accessors
            synthetic get a @-1
              reference: <testLibraryFragment>::@class::B::@getter::a
              enclosingElement: <testLibraryFragment>::@class::B
              returnType: A<String>
            synthetic set a= @-1
              reference: <testLibraryFragment>::@class::B::@setter::a
              enclosingElement: <testLibraryFragment>::@class::B
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
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @8
              element: <none>
          fields
            value @17
              reference: <testLibraryFragment>::@class::A::@field::value
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::value
              setter2: <testLibraryFragment>::@class::A::@setter::value
          constructors
            new @27
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                this.value @34
                  element: <none>
          getters
            get value @-1
              reference: <testLibraryFragment>::@class::A::@getter::value
              element: <none>
          setters
            set value= @-1
              reference: <testLibraryFragment>::@class::A::@setter::value
              element: <none>
              parameters
                _value @-1
                  element: <none>
        class B @51
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          fields
            a @61
              reference: <testLibraryFragment>::@class::B::@field::a
              element: <none>
              getter2: <testLibraryFragment>::@class::B::@getter::a
              setter2: <testLibraryFragment>::@class::B::@setter::a
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
          getters
            get a @-1
              reference: <testLibraryFragment>::@class::B::@getter::a
              element: <none>
          setters
            set a= @-1
              reference: <testLibraryFragment>::@class::B::@setter::a
              element: <none>
              parameters
                _a @-1
                  element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      fields
        value
          reference: <none>
          type: T
          firstFragment: <testLibraryFragment>::@class::A::@field::value
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final value
              reference: <none>
              type: T
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get value
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::value
      setters
        synthetic set value=
          reference: <none>
          parameters
            requiredPositional _value
              reference: <none>
              type: T
          firstFragment: <testLibraryFragment>::@class::A::@setter::value
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        a
          reference: <none>
          type: A<String>
          firstFragment: <testLibraryFragment>::@class::B::@field::a
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      getters
        synthetic get a
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@getter::a
      setters
        synthetic set a=
          reference: <none>
          parameters
            requiredPositional _a
              reference: <none>
              type: A<String>
          firstFragment: <testLibraryFragment>::@class::B::@setter::a
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            value @17
              reference: <testLibraryFragment>::@class::A::@field::value
              enclosingElement: <testLibraryFragment>::@class::A
              type: T
          constructors
            @27
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional final this.value @34
                  type: T
                  field: <testLibraryFragment>::@class::A::@field::value
          accessors
            synthetic get value @-1
              reference: <testLibraryFragment>::@class::A::@getter::value
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: T
            synthetic set value= @-1
              reference: <testLibraryFragment>::@class::A::@setter::value
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _value @-1
                  type: T
              returnType: void
        class alias B @51
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @53
              defaultType: dynamic
          supertype: A<T>
          mixins
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
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
                        staticType: T
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: T}
        class C @78
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            a @88
              reference: <testLibraryFragment>::@class::C::@field::a
              enclosingElement: <testLibraryFragment>::@class::C
              type: B<int>
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic get a @-1
              reference: <testLibraryFragment>::@class::C::@getter::a
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: B<int>
            synthetic set a= @-1
              reference: <testLibraryFragment>::@class::C::@setter::a
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _a @-1
                  type: B<int>
              returnType: void
      mixins
        mixin M @112
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @8
              element: <none>
          fields
            value @17
              reference: <testLibraryFragment>::@class::A::@field::value
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::value
              setter2: <testLibraryFragment>::@class::A::@setter::value
          constructors
            new @27
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                this.value @34
                  element: <none>
          getters
            get value @-1
              reference: <testLibraryFragment>::@class::A::@getter::value
              element: <none>
          setters
            set value= @-1
              reference: <testLibraryFragment>::@class::A::@setter::value
              element: <none>
              parameters
                _value @-1
                  element: <none>
        class B @51
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          typeParameters
            T @53
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
              parameters
                value @-1
                  element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      SimpleIdentifier
                        token: value @-1
                        staticElement: <testLibraryFragment>::@class::B::@constructor::new::@parameter::value
                        staticType: T
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: T}
        class C @78
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          fields
            a @88
              reference: <testLibraryFragment>::@class::C::@field::a
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::a
              setter2: <testLibraryFragment>::@class::C::@setter::a
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get a @-1
              reference: <testLibraryFragment>::@class::C::@getter::a
              element: <none>
          setters
            set a= @-1
              reference: <testLibraryFragment>::@class::C::@setter::a
              element: <none>
              parameters
                _a @-1
                  element: <none>
      mixins
        mixin M @112
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      fields
        value
          reference: <none>
          type: T
          firstFragment: <testLibraryFragment>::@class::A::@field::value
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final value
              reference: <none>
              type: T
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get value
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::value
      setters
        synthetic set value=
          reference: <none>
          parameters
            requiredPositional _value
              reference: <none>
              type: T
          firstFragment: <testLibraryFragment>::@class::A::@setter::value
    class alias B
      reference: <testLibraryFragment>::@class::B
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A<T>
      constructors
        synthetic new
          reference: <none>
          parameters
            requiredPositional final value
              reference: <none>
              type: T
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        a
          reference: <none>
          type: B<int>
          firstFragment: <testLibraryFragment>::@class::C::@field::a
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get a
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::a
      setters
        synthetic set a=
          reference: <none>
          parameters
            requiredPositional _a
              reference: <none>
              type: B<int>
          firstFragment: <testLibraryFragment>::@class::C::@setter::a
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            f @19
              reference: <testLibraryFragment>::@class::A::@field::f
              enclosingElement: <testLibraryFragment>::@class::A
              type: int
              shouldUseTypeForInitializerInference: false
          constructors
            @28
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional final this.f @35
                  type: int
                  field: <testLibraryFragment>::@class::A::@field::f
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::A::@getter::f
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: int
            synthetic set f= @-1
              reference: <testLibraryFragment>::@class::A::@setter::f
              enclosingElement: <testLibraryFragment>::@class::A
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
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @8
              element: <none>
          fields
            f @19
              reference: <testLibraryFragment>::@class::A::@field::f
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::f
              setter2: <testLibraryFragment>::@class::A::@setter::f
          constructors
            new @28
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                this.f @35
                  element: <none>
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::A::@getter::f
              element: <none>
          setters
            set f= @-1
              reference: <testLibraryFragment>::@class::A::@setter::f
              element: <none>
              parameters
                _f @-1
                  element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      fields
        f
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@field::f
          getter: <none>
          setter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final f
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get f
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::f
      setters
        synthetic set f=
          reference: <none>
          parameters
            requiredPositional _f
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::A::@setter::f
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            @12
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _ @14
                  type: dynamic
      topLevelVariables
        static final a @26
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final b @48
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A
          constructors
            new @12
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                _ @14
                  element: <none>
      topLevelVariables
        final a @26
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        final b @48
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    final a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    final b
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      reference: <none>
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
        package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static v @38
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement: <testLibraryFragment>
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
        v @38
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <none>
          parameters
            _v @-1
              element: <none>
  topLevelVariables
    v
      reference: <none>
      type: InvalidType
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      reference: <none>
      parameters
        requiredPositional _v
          reference: <none>
          type: InvalidType
      firstFragment: <testLibraryFragment>::@setter::v
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: dynamic Function(dynamic) Function(dynamic)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function(dynamic) Function(dynamic)
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
        x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    x
      reference: <none>
      type: dynamic Function(dynamic) Function(dynamic)
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: dynamic Function(dynamic) Function(dynamic)
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int Function(int) Function(int)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int Function(int) Function(int)
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
        x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    x
      reference: <none>
      type: int Function(int) Function(int)
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: int Function(int) Function(int)
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: dynamic Function([dynamic])
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function([dynamic])
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
        x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    x
      reference: <none>
      type: dynamic Function([dynamic])
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      reference: <none>
      parameters
        requiredPositional _x
          reference: <none>
          type: dynamic Function([dynamic])
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static final a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final c @32
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        final b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
        final c @32
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
  topLevelVariables
    final a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    final b
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
    final c
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get c
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static final a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final c @32
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        final b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
        final c @32
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
  topLevelVariables
    final a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    final b
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
    final c
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get c
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static final a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, d]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final c @36
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final d @49
          reference: <testLibraryFragment>::@topLevelVariable::d
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, d]
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get d @-1
          reference: <testLibraryFragment>::@getter::d
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        final b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
        final c @36
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
        final d @49
          reference: <testLibraryFragment>::@topLevelVariable::d
          element: <none>
          getter2: <testLibraryFragment>::@getter::d
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get d @-1
          reference: <testLibraryFragment>::@getter::d
          element: <none>
  topLevelVariables
    final a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    final b
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
    final c
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
    final d
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::d
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get d
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static final a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [a, b]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
        static final c @36
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          typeInferenceError: dependencyCycle
            arguments: [b, c]
          type: dynamic
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
        final b @19
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
        final c @36
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
  topLevelVariables
    final a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
    final b
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
    final c
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get c
      reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @18
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class C @40
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @42
              bound: A
              defaultType: A
          fields
            final f @67
              reference: <testLibraryFragment>::@class::C::@field::f
              enclosingElement: <testLibraryFragment>::@class::C
              type: T
          constructors
            const @78
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional final this.f @85
                  type: T
                  field: <testLibraryFragment>::@class::C::@field::f
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: T
      topLevelVariables
        static final b @98
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: B
          shouldUseTypeForInitializerInference: false
        static final c @113
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C<B>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: B
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @18
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class C @40
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @42
              element: <none>
          fields
            f @67
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            const new @78
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              parameters
                this.f @85
                  element: <none>
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <none>
      topLevelVariables
        final b @98
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
        final c @113
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
      getters
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: A
      firstFragment: <testLibraryFragment>::@class::C
      fields
        final f
          reference: <none>
          type: T
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional final f
              reference: <none>
              type: T
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get f
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
  topLevelVariables
    final b
      reference: <none>
      type: B
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
    final c
      reference: <none>
      type: C<B>
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
  getters
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get c
      reference: <none>
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
      enclosingElement: <testLibrary>
      extensions
        <null> @-1
          reference: <testLibraryFragment>::@extension::0
          enclosingElement: <testLibraryFragment>
          extendedType: String
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@extension::0::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::0
              type: int
          accessors
            get foo @32
              reference: <testLibraryFragment>::@extension::0::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::0
              returnType: int
      topLevelVariables
        static v @48
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement: <testLibraryFragment>
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
        extension  @-1
          reference: <testLibraryFragment>::@extension::0
          element: <testLibraryFragment>::@extension::0
          fields
            foo @-1
              reference: <testLibraryFragment>::@extension::0::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@extension::0::@getter::foo
          getters
            get foo @32
              reference: <testLibraryFragment>::@extension::0::@getter::foo
              element: <none>
      topLevelVariables
        v @48
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <none>
          parameters
            _v @-1
              element: <none>
  extensions
    extension <null>
      reference: <testLibraryFragment>::@extension::0
      firstFragment: <testLibraryFragment>::@extension::0
      fields
        synthetic foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extension::0::@field::foo
          getter: <none>
      getters
        get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@extension::0::@getter::foo
  topLevelVariables
    v
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      reference: <none>
      parameters
        requiredPositional _v
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::v
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              bound: dynamic
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
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
          enclosingElement: <testLibraryFragment>
          type: dynamic
          shouldUseTypeForInitializerInference: true
        static V @71
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get V2 @-1
          reference: <testLibraryFragment>::@getter::V2
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static set V2= @-1
          reference: <testLibraryFragment>::@setter::V2
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _V2 @-1
              type: dynamic
          returnType: void
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set V= @-1
          reference: <testLibraryFragment>::@setter::V
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _V @-1
              type: int
          returnType: void
      functions
        f @44
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @8
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      typeAliases
        F @34
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
      topLevelVariables
        V2 @56
          reference: <testLibraryFragment>::@topLevelVariable::V2
          element: <none>
          getter2: <testLibraryFragment>::@getter::V2
          setter2: <testLibraryFragment>::@setter::V2
        V @71
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <none>
          getter2: <testLibraryFragment>::@getter::V
          setter2: <testLibraryFragment>::@setter::V
      getters
        get V2 @-1
          reference: <testLibraryFragment>::@getter::V2
          element: <none>
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <none>
      setters
        set V2= @-1
          reference: <testLibraryFragment>::@setter::V2
          element: <none>
          parameters
            _V2 @-1
              element: <none>
        set V= @-1
          reference: <testLibraryFragment>::@setter::V
          element: <none>
          parameters
            _V @-1
              element: <none>
      functions
        f @44
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            p @48
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: dynamic
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function(dynamic)
  topLevelVariables
    V2
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::V2
      getter: <none>
      setter: <none>
    V
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      getter: <none>
      setter: <none>
  getters
    synthetic static get V2
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::V2
    synthetic static get V
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::V
  setters
    synthetic static set V2=
      reference: <none>
      parameters
        requiredPositional _V2
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::V2
    synthetic static set V=
      reference: <none>
      parameters
        requiredPositional _V
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::V
  functions
    f
      reference: <none>
      parameters
        requiredPositional p
          reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static V @4
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement: <testLibraryFragment>
          type: dynamic
        static V2 @22
          reference: <testLibraryFragment>::@topLevelVariable::V2
          enclosingElement: <testLibraryFragment>
          type: List<dynamic>
      accessors
        synthetic static get V @-1
          reference: <testLibraryFragment>::@getter::V
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static set V= @-1
          reference: <testLibraryFragment>::@setter::V
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _V @-1
              type: dynamic
          returnType: void
        synthetic static get V2 @-1
          reference: <testLibraryFragment>::@getter::V2
          enclosingElement: <testLibraryFragment>
          returnType: List<dynamic>
        synthetic static set V2= @-1
          reference: <testLibraryFragment>::@setter::V2
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::V
          setter2: <testLibraryFragment>::@setter::V
        V2 @22
          reference: <testLibraryFragment>::@topLevelVariable::V2
          element: <none>
          getter2: <testLibraryFragment>::@getter::V2
          setter2: <testLibraryFragment>::@setter::V2
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <none>
        get V2 @-1
          reference: <testLibraryFragment>::@getter::V2
          element: <none>
      setters
        set V= @-1
          reference: <testLibraryFragment>::@setter::V
          element: <none>
          parameters
            _V @-1
              element: <none>
        set V2= @-1
          reference: <testLibraryFragment>::@setter::V2
          element: <none>
          parameters
            _V2 @-1
              element: <none>
  topLevelVariables
    V
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      getter: <none>
      setter: <none>
    V2
      reference: <none>
      type: List<dynamic>
      firstFragment: <testLibraryFragment>::@topLevelVariable::V2
      getter: <none>
      setter: <none>
  getters
    synthetic static get V
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::V
    synthetic static get V2
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::V2
  setters
    synthetic static set V=
      reference: <none>
      parameters
        requiredPositional _V
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::V
    synthetic static set V2=
      reference: <none>
      parameters
        requiredPositional _V2
          reference: <none>
          type: List<dynamic>
      firstFragment: <testLibraryFragment>::@setter::V2
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            m @15
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement: <testLibraryFragment>::@class::C
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @8
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          methods
            m @15
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <none>
              parameters
                p @21
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        m
          reference: <none>
          parameters
            requiredPositional p
              reference: <none>
              type: InvalidType
          firstFragment: <testLibraryFragment>::@class::C::@method::m
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static v @4
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: InvalidType
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <none>
          parameters
            _v @-1
              element: <none>
  topLevelVariables
    v
      reference: <none>
      type: InvalidType
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      reference: <none>
      parameters
        requiredPositional _v
          reference: <none>
          type: InvalidType
      firstFragment: <testLibraryFragment>::@setter::v
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static d @6
          reference: <testLibraryFragment>::@topLevelVariable::d
          enclosingElement: <testLibraryFragment>
          type: Never
      accessors
        synthetic static get d @-1
          reference: <testLibraryFragment>::@getter::d
          enclosingElement: <testLibraryFragment>
          returnType: Never
        synthetic static set d= @-1
          reference: <testLibraryFragment>::@setter::d
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::d
          setter2: <testLibraryFragment>::@setter::d
      getters
        get d @-1
          reference: <testLibraryFragment>::@getter::d
          element: <none>
      setters
        set d= @-1
          reference: <testLibraryFragment>::@setter::d
          element: <none>
          parameters
            _d @-1
              element: <none>
  topLevelVariables
    d
      reference: <none>
      type: Never
      firstFragment: <testLibraryFragment>::@topLevelVariable::d
      getter: <none>
      setter: <none>
  getters
    synthetic static get d
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::d
  setters
    synthetic static set d=
      reference: <none>
      parameters
        requiredPositional _d
          reference: <none>
          type: Never
      firstFragment: <testLibraryFragment>::@setter::d
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            t @17
              reference: <testLibraryFragment>::@class::C::@field::t
              enclosingElement: <testLibraryFragment>::@class::C
              type: T
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic get t @-1
              reference: <testLibraryFragment>::@class::C::@getter::t
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: T
            synthetic set t= @-1
              reference: <testLibraryFragment>::@class::C::@setter::t
              enclosingElement: <testLibraryFragment>::@class::C
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @8
              element: <none>
          fields
            t @17
              reference: <testLibraryFragment>::@class::C::@field::t
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::t
              setter2: <testLibraryFragment>::@class::C::@setter::t
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get t @-1
              reference: <testLibraryFragment>::@class::C::@getter::t
              element: <none>
          setters
            set t= @-1
              reference: <testLibraryFragment>::@class::C::@setter::t
              element: <none>
              parameters
                _t @-1
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::C
      fields
        t
          reference: <none>
          type: T
          firstFragment: <testLibraryFragment>::@class::C::@field::t
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get t
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::t
      setters
        synthetic set t=
          reference: <none>
          parameters
            requiredPositional _t
              reference: <none>
              type: T
          firstFragment: <testLibraryFragment>::@class::C::@setter::t
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          fields
            t @18
              reference: <testLibraryFragment>::@class::C::@field::t
              enclosingElement: <testLibraryFragment>::@class::C
              type: T?
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          accessors
            synthetic get t @-1
              reference: <testLibraryFragment>::@class::C::@getter::t
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: T?
            synthetic set t= @-1
              reference: <testLibraryFragment>::@class::C::@setter::t
              enclosingElement: <testLibraryFragment>::@class::C
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @8
              element: <none>
          fields
            t @18
              reference: <testLibraryFragment>::@class::C::@field::t
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::t
              setter2: <testLibraryFragment>::@class::C::@setter::t
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get t @-1
              reference: <testLibraryFragment>::@class::C::@getter::t
              element: <none>
          setters
            set t= @-1
              reference: <testLibraryFragment>::@class::C::@setter::t
              element: <none>
              parameters
                _t @-1
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::C
      fields
        t
          reference: <none>
          type: T?
          firstFragment: <testLibraryFragment>::@class::C::@field::t
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get t
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::t
      setters
        synthetic set t=
          reference: <none>
          parameters
            requiredPositional _t
              reference: <none>
              type: T?
          firstFragment: <testLibraryFragment>::@class::C::@setter::t
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      enums
        enum E @16
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @20
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
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
          enclosingElement: <testLibraryFragment>
          type: C
        static e @44
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement: <testLibraryFragment>
          type: E
        static f @49
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      enums
        enum E @16
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @20
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      typeAliases
        F @32
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
      topLevelVariables
        c @39
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @44
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <none>
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @49
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get e @-1
          reference: <testLibraryFragment>::@getter::e
          element: <none>
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibraryFragment>::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: <testLibraryFragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibraryFragment>::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibraryFragment>::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@setter::f
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
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        static c @28
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C
        static e @33
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement: <testLibraryFragment>
          type: E
        static f @38
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class C @17
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::C
      enums
        enum E @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          supertype: Enum
          fields
            static const enumConstant v @31
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::E
                      type: E
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @33
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <none>
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @38
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get e @-1
          reference: <testLibraryFragment>::@getter::e
          element: <none>
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibraryFragment>::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class C @17
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          element: <testLibrary>::@fragment::package:test/a.dart::@class::C
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              element: <none>
      enums
        enum E @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          element: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          fields
            enumConstant v @31
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
            values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
              element: <none>
      typeAliases
        F @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          element: <none>
  classes
    class C
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
  enums
    enum E
      reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibraryFragment>::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibraryFragment>::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      firstFragment: <testLibraryFragment>::@setter::f
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
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class C @32
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      enums
        enum E @42
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @46
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
      typeAliases
        functionTypeAliasBased F @58
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @13
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::c
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: C
        static e @18
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::e
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: E
        static f @23
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::c
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: C
        synthetic static set c= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::c
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::e
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: E
        synthetic static set e= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::e
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::f
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      enums
        enum E @42
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @46
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      typeAliases
        F @58
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        c @13
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::c
          element: <none>
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::c
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::c
        e @18
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::e
          element: <none>
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::e
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::e
        f @23
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
          element: <none>
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::f
      getters
        get c @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::c
          element: <none>
        get e @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::e
          element: <none>
        get f @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: <testLibraryFragment>::@typeAlias::F
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::f
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
  parts
    part_0
    part_1
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class C @17
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::C
      enums
        enum E @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          supertype: Enum
          fields
            static const enumConstant v @31
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::E
                      type: E
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              returnType: List<E>
      typeAliases
        functionTypeAliasBased F @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @13
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::c
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          type: C
        static e @18
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::e
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          type: E
        static f @23
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::f
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          type: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::c
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          returnType: C
        synthetic static set c= @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::c
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::e
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          returnType: E
        synthetic static set e= @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::e
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::f
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          returnType: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::f
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
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
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class C @17
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          element: <testLibrary>::@fragment::package:test/a.dart::@class::C
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              element: <none>
      enums
        enum E @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          element: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          fields
            enumConstant v @31
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
            values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
              element: <none>
      typeAliases
        F @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          element: <none>
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        c @13
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::c
          element: <none>
          getter2: <testLibrary>::@fragment::package:test/b.dart::@getter::c
          setter2: <testLibrary>::@fragment::package:test/b.dart::@setter::c
        e @18
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::e
          element: <none>
          getter2: <testLibrary>::@fragment::package:test/b.dart::@getter::e
          setter2: <testLibrary>::@fragment::package:test/b.dart::@setter::e
        f @23
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::f
          element: <none>
          getter2: <testLibrary>::@fragment::package:test/b.dart::@getter::f
          setter2: <testLibrary>::@fragment::package:test/b.dart::@setter::f
      getters
        get c @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::c
          element: <none>
        get e @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::e
          element: <none>
        get f @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  classes
    class C
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
  enums
    enum E
      reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@setter::f
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
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class C @17
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::C
      enums
        enum E @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          supertype: Enum
          fields
            static const enumConstant v @31
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::E
                      type: E
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::E
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
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: C
        static e @55
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::e
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: E
        static f @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::c
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: C
        synthetic static set c= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::c
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::e
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: E
        synthetic static set e= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::e
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::f
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
      previousFragment: <testLibraryFragment>
      classes
        class C @17
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          element: <testLibrary>::@fragment::package:test/a.dart::@class::C
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              element: <none>
      enums
        enum E @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          element: <testLibrary>::@fragment::package:test/a.dart::@enum::E
          fields
            enumConstant v @31
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
            values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
              element: <none>
      typeAliases
        F @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
          element: <none>
      topLevelVariables
        c @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::c
          element: <none>
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::c
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::c
        e @55
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::e
          element: <none>
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::e
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::e
        f @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
          element: <none>
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::f
      getters
        get c @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::c
          element: <none>
        get e @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::e
          element: <none>
        get f @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  classes
    class C
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
  enums
    enum E
      reference: <testLibrary>::@fragment::package:test/a.dart::@enum::E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::E::@getter::values
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: <testLibrary>::@fragment::package:test/a.dart::@typeAlias::F
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::f
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      topLevelVariables
        static c @13
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      topLevelVariables
        c @13
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibraryFragment>::@setter::c
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
            covariant U @11
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      topLevelVariables
        static c @32
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C<int, String>
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C<int, String>
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @8
              element: <none>
            U @11
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      topLevelVariables
        c @32
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
        U
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    c
      reference: <none>
      type: C<int, String>
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C<int, String>
      firstFragment: <testLibraryFragment>::@setter::c
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
            covariant U @11
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      topLevelVariables
        static c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C<dynamic, dynamic>
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C<dynamic, dynamic>
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @8
              element: <none>
            U @11
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      topLevelVariables
        c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
        U
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    c
      reference: <none>
      type: C<dynamic, dynamic>
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C<dynamic, dynamic>
      firstFragment: <testLibraryFragment>::@setter::c
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
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @9
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static e @15
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement: <testLibraryFragment>
          type: E
      accessors
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement: <testLibraryFragment>
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
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @9
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      topLevelVariables
        e @15
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <none>
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
      getters
        get e @-1
          reference: <testLibraryFragment>::@getter::e
          element: <none>
      setters
        set e= @-1
          reference: <testLibraryFragment>::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    e
      reference: <none>
      type: E
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      getter: <none>
      setter: <none>
  getters
    synthetic static get e
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::e
  setters
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibraryFragment>::@setter::e
''');
  }

  test_type_reference_to_import() async {
    newFile(
        '$testPackageLibPath/a.dart', 'class C {} enum E { v } typedef F();');
    var library = await buildLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C
        static e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement: <testLibraryFragment>
          type: E
        static f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/a.dart::<fragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/a.dart::<fragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <none>
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get e @-1
          reference: <testLibraryFragment>::@getter::e
          element: <none>
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibraryFragment>::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: package:test/a.dart::<fragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibraryFragment>::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibraryFragment>::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: package:test/a.dart::<fragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@setter::f
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C
        static e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement: <testLibraryFragment>
          type: E
        static f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/b.dart::<fragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/b.dart::<fragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <none>
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get e @-1
          reference: <testLibraryFragment>::@getter::e
          element: <none>
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibraryFragment>::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: package:test/b.dart::<fragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibraryFragment>::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibraryFragment>::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: package:test/b.dart::<fragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@setter::f
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C
        static e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement: <testLibraryFragment>
          type: E
        static f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/c.dart::<fragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/c.dart::<fragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <none>
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get e @-1
          reference: <testLibraryFragment>::@getter::e
          element: <none>
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibraryFragment>::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: package:test/c.dart::<fragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibraryFragment>::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibraryFragment>::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: package:test/c.dart::<fragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@setter::f
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
  libraryImports
    package:test/a/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @21
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C
        static e @26
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement: <testLibraryFragment>
          type: E
        static f @31
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/a/c/c.dart::<fragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/a/c/c.dart::<fragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @26
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <none>
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @31
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get e @-1
          reference: <testLibraryFragment>::@getter::e
          element: <none>
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibraryFragment>::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: package:test/a/c/c.dart::<fragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibraryFragment>::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibraryFragment>::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: package:test/a/c/c.dart::<fragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@setter::f
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
  libraryImports
    package:test/a/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @21
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C
        static e @26
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement: <testLibraryFragment>
          type: E
        static f @31
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/a/b/b.dart::<fragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/a/b/b.dart::<fragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @26
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <none>
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @31
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get e @-1
          reference: <testLibraryFragment>::@getter::e
          element: <none>
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibraryFragment>::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: package:test/a/b/b.dart::<fragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibraryFragment>::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibraryFragment>::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: package:test/a/b/b.dart::<fragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@setter::f
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C
        static e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement: <testLibraryFragment>
          type: E
        static f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/a.dart::@fragment::package:test/b.dart::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/a.dart::@fragment::package:test/b.dart::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <none>
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get e @-1
          reference: <testLibraryFragment>::@getter::e
          element: <none>
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibraryFragment>::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: package:test/a.dart::@fragment::package:test/b.dart::@typeAlias::F
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibraryFragment>::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibraryFragment>::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: package:test/a.dart::@fragment::package:test/b.dart::@typeAlias::F
      firstFragment: <testLibraryFragment>::@setter::f
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c1 @20
          reference: <testLibraryFragment>::@topLevelVariable::c1
          enclosingElement: <testLibraryFragment>
          type: C1
        static c2 @27
          reference: <testLibraryFragment>::@topLevelVariable::c2
          enclosingElement: <testLibraryFragment>
          type: C2
      accessors
        synthetic static get c1 @-1
          reference: <testLibraryFragment>::@getter::c1
          enclosingElement: <testLibraryFragment>
          returnType: C1
        synthetic static set c1= @-1
          reference: <testLibraryFragment>::@setter::c1
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c1 @-1
              type: C1
          returnType: void
        synthetic static get c2 @-1
          reference: <testLibraryFragment>::@getter::c2
          enclosingElement: <testLibraryFragment>
          returnType: C2
        synthetic static set c2= @-1
          reference: <testLibraryFragment>::@setter::c2
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::c1
          setter2: <testLibraryFragment>::@setter::c1
        c2 @27
          reference: <testLibraryFragment>::@topLevelVariable::c2
          element: <none>
          getter2: <testLibraryFragment>::@getter::c2
          setter2: <testLibraryFragment>::@setter::c2
      getters
        get c1 @-1
          reference: <testLibraryFragment>::@getter::c1
          element: <none>
        get c2 @-1
          reference: <testLibraryFragment>::@getter::c2
          element: <none>
      setters
        set c1= @-1
          reference: <testLibraryFragment>::@setter::c1
          element: <none>
          parameters
            _c1 @-1
              element: <none>
        set c2= @-1
          reference: <testLibraryFragment>::@setter::c2
          element: <none>
          parameters
            _c2 @-1
              element: <none>
  topLevelVariables
    c1
      reference: <none>
      type: C1
      firstFragment: <testLibraryFragment>::@topLevelVariable::c1
      getter: <none>
      setter: <none>
    c2
      reference: <none>
      type: C2
      firstFragment: <testLibraryFragment>::@topLevelVariable::c2
      getter: <none>
      setter: <none>
  getters
    synthetic static get c1
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c1
    synthetic static get c2
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c2
  setters
    synthetic static set c1=
      reference: <none>
      parameters
        requiredPositional _c1
          reference: <none>
          type: C1
      firstFragment: <testLibraryFragment>::@setter::c1
    synthetic static set c2=
      reference: <none>
      parameters
        requiredPositional _c2
          reference: <none>
          type: C2
      firstFragment: <testLibraryFragment>::@setter::c2
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
  libraryImports
    package:test/a/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @21
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C
        static e @26
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement: <testLibraryFragment>
          type: E
        static f @31
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/a/b.dart::@fragment::package:test/a/c.dart::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/a/b.dart::@fragment::package:test/a/c.dart::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @26
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <none>
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @31
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get e @-1
          reference: <testLibraryFragment>::@getter::e
          element: <none>
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibraryFragment>::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: package:test/a/b.dart::@fragment::package:test/a/c.dart::@typeAlias::F
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibraryFragment>::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibraryFragment>::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: package:test/a/b.dart::@fragment::package:test/a/c.dart::@typeAlias::F
      firstFragment: <testLibraryFragment>::@setter::f
''');
  }

  test_type_reference_to_import_relative() async {
    newFile(
        '$testPackageLibPath/a.dart', 'class C {} enum E { v } typedef F();');
    var library = await buildLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @19
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C
        static e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          enclosingElement: <testLibraryFragment>
          type: E
        static f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
            alias: package:test/a.dart::<fragment>::@typeAlias::F
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          reference: <testLibraryFragment>::@getter::e
          enclosingElement: <testLibraryFragment>
          returnType: E
        synthetic static set e= @-1
          reference: <testLibraryFragment>::@setter::e
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
            alias: package:test/a.dart::<fragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        e @24
          reference: <testLibraryFragment>::@topLevelVariable::e
          element: <none>
          getter2: <testLibraryFragment>::@getter::e
          setter2: <testLibraryFragment>::@setter::e
        f @29
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get e @-1
          reference: <testLibraryFragment>::@getter::e
          element: <none>
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set e= @-1
          reference: <testLibraryFragment>::@setter::e
          element: <none>
          parameters
            _e @-1
              element: <none>
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  topLevelVariables
    c
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      getter: <none>
      setter: <none>
    e
      reference: <none>
      type: E
      firstFragment: <testLibraryFragment>::@topLevelVariable::e
      getter: <none>
      setter: <none>
    f
      reference: <none>
      type: dynamic Function()
        alias: package:test/a.dart::<fragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get e
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::e
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set c=
      reference: <none>
      parameters
        requiredPositional _c
          reference: <none>
          type: C
      firstFragment: <testLibraryFragment>::@setter::c
    synthetic static set e=
      reference: <none>
      parameters
        requiredPositional _e
          reference: <none>
          type: E
      firstFragment: <testLibraryFragment>::@setter::e
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: package:test/a.dart::<fragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@setter::f
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
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
      topLevelVariables
        static f @15
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
      topLevelVariables
        f @15
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function()
  topLevelVariables
    f
      reference: <none>
      type: dynamic Function()
        alias: <testLibraryFragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::F
      firstFragment: <testLibraryFragment>::@setter::f
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
      enclosingElement: <testLibrary>
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
          enclosingElement: <testLibraryFragment>
          type: String Function(int)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                int
                String
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: String Function(int)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                int
                String
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          typeParameters
            T @12
              element: <none>
            U @15
              element: <none>
      topLevelVariables
        f @39
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
        U
      aliasedType: U Function(T)
  topLevelVariables
    f
      reference: <none>
      type: String Function(int)
        alias: <testLibraryFragment>::@typeAlias::F
          typeArguments
            int
            String
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: String Function(int)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                int
                String
      firstFragment: <testLibraryFragment>::@setter::f
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
      enclosingElement: <testLibrary>
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
          enclosingElement: <testLibraryFragment>
          type: dynamic Function(dynamic)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                dynamic
                dynamic
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic Function(dynamic)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                dynamic
                dynamic
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
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
          element: <none>
          typeParameters
            T @12
              element: <none>
            U @15
              element: <none>
      topLevelVariables
        f @26
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
        U
      aliasedType: U Function(T)
  topLevelVariables
    f
      reference: <none>
      type: dynamic Function(dynamic)
        alias: <testLibraryFragment>::@typeAlias::F
          typeArguments
            dynamic
            dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: dynamic Function(dynamic)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                dynamic
                dynamic
      firstFragment: <testLibraryFragment>::@setter::f
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
