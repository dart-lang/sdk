// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypesElementTest_keepLinking);
    defineReflectiveTests(TypesElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class TypesElementTest extends ElementsBaseTest {
  test_closure_executable_with_return_type_from_closure() async {
    var library = await buildLibrary('''
f() {
  print(() {});
  print(() => () => 0);
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
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: dynamic
''');
  }

  test_executable_parameter_type_typedef() async {
    var library = await buildLibrary(r'''
typedef F(int p);
main(F f) {}
''');
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
          aliasedType: dynamic Function(int)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional p @14
                type: int
            returnType: dynamic
      functions
        main @18
          reference: <testLibraryFragment>::@function::main
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional f @25
              type: dynamic Function(int)
                alias: <testLibraryFragment>::@typeAlias::F
          returnType: dynamic
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
      functions
        main @18
          reference: <testLibraryFragment>::@function::main
          element: <none>
          parameters
            f @25
              element: <none>
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: dynamic Function(int)
  functions
    main
      firstFragment: <testLibraryFragment>::@function::main
      parameters
        requiredPositional f
          type: dynamic Function(int)
            alias: <testLibraryFragment>::@typeAlias::F
      returnType: dynamic
''');
  }

  test_futureOr() async {
    var library = await buildLibrary('import "dart:async"; FutureOr<int> x;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:async
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static x @35
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: FutureOr<int>
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: FutureOr<int>
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: FutureOr<int>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: FutureOr<int>
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      parameters
        requiredPositional _x
          type: FutureOr<int>
''');
    var variables = library.definingCompilationUnit.topLevelVariables;
    expect(variables, hasLength(1));
    _assertTypeStr(variables[0].type, 'FutureOr<int>');
  }

  test_futureOr_const() async {
    var library =
        await buildLibrary('import "dart:async"; const x = FutureOr;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:async
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const x @27
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: Type
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: FutureOr @31
              staticElement: dart:async::<fragment>::@class::FutureOr
              staticType: Type
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: Type
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        const x @27
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <none>
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Type
      getter: <none>
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
''');
    var variables = library.definingCompilationUnit.topLevelVariables;
    expect(variables, hasLength(1));
    var x = variables[0] as ConstTopLevelVariableElementImpl;
    _assertTypeStr(x.type, 'Type');
    expect(x.constantInitializer.toString(), 'FutureOr');
  }

  test_futureOr_inferred() async {
    var library = await buildLibrary('''
import "dart:async";
FutureOr<int> f() => null;
var x = f();
var y = x.then((z) => z.asDouble());
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:async
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static x @52
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: FutureOr<int>
          shouldUseTypeForInitializerInference: false
        static y @65
          reference: <testLibraryFragment>::@topLevelVariable::y
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: FutureOr<int>
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: FutureOr<int>
          returnType: void
        synthetic static get y @-1
          reference: <testLibraryFragment>::@getter::y
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
        synthetic static set y= @-1
          reference: <testLibraryFragment>::@setter::y
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _y @-1
              type: InvalidType
          returnType: void
      functions
        f @35
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          returnType: FutureOr<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        x @52
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <none>
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
        y @65
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
      functions
        f @35
          reference: <testLibraryFragment>::@function::f
          element: <none>
  topLevelVariables
    x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: FutureOr<int>
      getter: <none>
      setter: <none>
    y
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      type: InvalidType
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
    synthetic static get y
      firstFragment: <testLibraryFragment>::@getter::y
  setters
    synthetic static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      parameters
        requiredPositional _x
          type: FutureOr<int>
    synthetic static set y=
      firstFragment: <testLibraryFragment>::@setter::y
      parameters
        requiredPositional _y
          type: InvalidType
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: FutureOr<int>
''');
    var variables = library.definingCompilationUnit.topLevelVariables;
    expect(variables, hasLength(2));
    var x = variables[0];
    expect(x.name, 'x');
    var y = variables[1];
    expect(y.name, 'y');
    _assertTypeStr(x.type, 'FutureOr<int>');
    _assertTypeStr(y.type, 'InvalidType');
  }

  test_generic_gClass_gMethodStatic() async {
    var library = await buildLibrary('''
class C<T, U> {
  static void m<V, W>(V v, W w) {
    void f<X, Y>(V v, W w, X x, Y y) {
    }
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
            covariant U @11
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            static m @30
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement3: <testLibraryFragment>::@class::C
              typeParameters
                covariant V @32
                  defaultType: dynamic
                covariant W @35
                  defaultType: dynamic
              parameters
                requiredPositional v @40
                  type: V
                requiredPositional w @45
                  type: W
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
          methods
            m @30
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <none>
              typeParameters
                V @32
                  element: <none>
                W @35
                  element: <none>
              parameters
                v @40
                  element: <none>
                w @45
                  element: <none>
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
        U
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        static m
          firstFragment: <testLibraryFragment>::@class::C::@method::m
          typeParameters
            V
            W
          parameters
            requiredPositional v
              type: V
            requiredPositional w
              type: W
''');
  }

  test_implicitCallTearoff() async {
    var library = await buildLibrary(r'''
class C {
  void call() {}
}

class D {
  const D(C c) : this.named(c);

  const D.named(void Function() f);
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
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            call @17
              reference: <testLibraryFragment>::@class::C::@method::call
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: void
        class D @36
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          constructors
            const @48
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
              parameters
                requiredPositional c @52
                  type: C
              constantInitializers
                RedirectingConstructorInvocation
                  thisKeyword: this @57
                  period: . @61
                  constructorName: SimpleIdentifier
                    token: named @62
                    staticElement: <testLibraryFragment>::@class::D::@constructor::named
                    staticType: null
                  argumentList: ArgumentList
                    leftParenthesis: ( @67
                    arguments
                      ImplicitCallReference
                        expression: SimpleIdentifier
                          token: c @68
                          staticElement: <testLibraryFragment>::@class::D::@constructor::new::@parameter::c
                          staticType: C
                        staticElement: <testLibraryFragment>::@class::C::@method::call
                        staticType: void Function()
                    rightParenthesis: ) @69
                  staticElement: <testLibraryFragment>::@class::D::@constructor::named
              redirectedConstructor: <testLibraryFragment>::@class::D::@constructor::named
            const named @83
              reference: <testLibraryFragment>::@class::D::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::D
              periodOffset: 82
              nameEnd: 88
              parameters
                requiredPositional f @105
                  type: void Function()
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
          methods
            call @17
              reference: <testLibraryFragment>::@class::C::@method::call
              element: <none>
        class D @36
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            const new @48
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
              parameters
                c @52
                  element: <none>
              constantInitializers
                RedirectingConstructorInvocation
                  thisKeyword: this @57
                  period: . @61
                  constructorName: SimpleIdentifier
                    token: named @62
                    staticElement: <testLibraryFragment>::@class::D::@constructor::named
                    staticType: null
                  argumentList: ArgumentList
                    leftParenthesis: ( @67
                    arguments
                      ImplicitCallReference
                        expression: SimpleIdentifier
                          token: c @68
                          staticElement: <testLibraryFragment>::@class::D::@constructor::new::@parameter::c
                          staticType: C
                        staticElement: <testLibraryFragment>::@class::C::@method::call
                        staticType: void Function()
                    rightParenthesis: ) @69
                  staticElement: <testLibraryFragment>::@class::D::@constructor::named
              redirectedConstructor: <testLibraryFragment>::@class::D::@constructor::named
            const named @83
              reference: <testLibraryFragment>::@class::D::@constructor::named
              element: <none>
              periodOffset: 82
              nameEnd: 88
              parameters
                f @105
                  element: <none>
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        call
          firstFragment: <testLibraryFragment>::@class::C::@method::call
    class D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
          parameters
            requiredPositional c
              type: C
          redirectedConstructor: <none>
        const named
          firstFragment: <testLibraryFragment>::@class::D::@constructor::named
          parameters
            requiredPositional f
              type: void Function()
''');
  }

  test_initializer_executable_with_return_type_from_closure() async {
    var library = await buildLibrary('var v = () => 0;');
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
          type: int Function()
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int Function()
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: int Function()
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function()
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      firstFragment: <testLibraryFragment>::@setter::v
      parameters
        requiredPositional _v
          type: int Function()
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_dynamic() async {
    var library = await buildLibrary('var v = (f) async => await f;');
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
          type: Future<dynamic> Function(dynamic)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: Future<dynamic> Function(dynamic)
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: Future<dynamic> Function(dynamic)
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: Future<dynamic> Function(dynamic)
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      firstFragment: <testLibraryFragment>::@setter::v
      parameters
        requiredPositional _v
          type: Future<dynamic> Function(dynamic)
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_future3_int() async {
    var library = await buildLibrary(r'''
import 'dart:async';
var v = (Future<Future<Future<int>>> f) async => await f;
''');
    // The analyzer type system over-flattens - see dartbug.com/31887
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:async
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static v @25
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: Future<int> Function(Future<Future<Future<int>>>)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: Future<int> Function(Future<Future<Future<int>>>)
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: Future<int> Function(Future<Future<Future<int>>>)
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        v @25
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: Future<int> Function(Future<Future<Future<int>>>)
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      firstFragment: <testLibraryFragment>::@setter::v
      parameters
        requiredPositional _v
          type: Future<int> Function(Future<Future<Future<int>>>)
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_future_int() async {
    var library = await buildLibrary(r'''
import 'dart:async';
var v = (Future<int> f) async => await f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:async
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static v @25
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: Future<int> Function(Future<int>)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: Future<int> Function(Future<int>)
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: Future<int> Function(Future<int>)
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        v @25
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: Future<int> Function(Future<int>)
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      firstFragment: <testLibraryFragment>::@setter::v
      parameters
        requiredPositional _v
          type: Future<int> Function(Future<int>)
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_future_noArg() async {
    var library = await buildLibrary(r'''
import 'dart:async';
var v = (Future f) async => await f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:async
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static v @25
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: Future<dynamic> Function(Future<dynamic>)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: Future<dynamic> Function(Future<dynamic>)
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: Future<dynamic> Function(Future<dynamic>)
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        v @25
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: Future<dynamic> Function(Future<dynamic>)
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      firstFragment: <testLibraryFragment>::@setter::v
      parameters
        requiredPositional _v
          type: Future<dynamic> Function(Future<dynamic>)
''');
  }

  test_initializer_executable_with_return_type_from_closure_field() async {
    var library = await buildLibrary('''
class C {
  var v = () => 0;
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
          fields
            v @16
              reference: <testLibraryFragment>::@class::C::@field::v
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int Function()
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get v @-1
              reference: <testLibraryFragment>::@class::C::@getter::v
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int Function()
            synthetic set v= @-1
              reference: <testLibraryFragment>::@class::C::@setter::v
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _v @-1
                  type: int Function()
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
            v @16
              reference: <testLibraryFragment>::@class::C::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::v
              setter2: <testLibraryFragment>::@class::C::@setter::v
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
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
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        v
          firstFragment: <testLibraryFragment>::@class::C::@field::v
          type: int Function()
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get v
          firstFragment: <testLibraryFragment>::@class::C::@getter::v
      setters
        synthetic set v=
          firstFragment: <testLibraryFragment>::@class::C::@setter::v
          parameters
            requiredPositional _v
              type: int Function()
''');
  }

  test_initializer_executable_with_return_type_from_closure_local() async {
    var library = await buildLibrary('''
void f() {
  int u = 0;
  var v = () => 0;
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
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
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
          element: <none>
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: void
''');
  }

  test_instanceInference_operator_equal_from() async {
    newFile('$testPackageLibPath/nullSafe.dart', r'''
class NullSafeDefault {
  bool operator==(other) => false;
}
class NullSafeObject {
  bool operator==(Object other) => false;
}
class NullSafeInt {
  bool operator==(int other) => false;
}
''');
    var library = await buildLibrary(r'''
import 'nullSafe.dart';
class X1 extends NullSafeDefault {
  bool operator==(other) => false;
}
class X2 extends NullSafeObject {
  bool operator==(other) => false;
}
class X3 extends NullSafeInt {
  bool operator==(other) => false;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/nullSafe.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/nullSafe.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class X1 @30
          reference: <testLibraryFragment>::@class::X1
          enclosingElement3: <testLibraryFragment>
          supertype: NullSafeDefault
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::X1
              superConstructor: package:test/nullSafe.dart::<fragment>::@class::NullSafeDefault::@constructor::new
          methods
            == @74
              reference: <testLibraryFragment>::@class::X1::@method::==
              enclosingElement3: <testLibraryFragment>::@class::X1
              parameters
                requiredPositional other @77
                  type: Object
              returnType: bool
        class X2 @102
          reference: <testLibraryFragment>::@class::X2
          enclosingElement3: <testLibraryFragment>
          supertype: NullSafeObject
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X2::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::X2
              superConstructor: package:test/nullSafe.dart::<fragment>::@class::NullSafeObject::@constructor::new
          methods
            == @145
              reference: <testLibraryFragment>::@class::X2::@method::==
              enclosingElement3: <testLibraryFragment>::@class::X2
              parameters
                requiredPositional other @148
                  type: Object
              returnType: bool
        class X3 @173
          reference: <testLibraryFragment>::@class::X3
          enclosingElement3: <testLibraryFragment>
          supertype: NullSafeInt
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X3::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::X3
              superConstructor: package:test/nullSafe.dart::<fragment>::@class::NullSafeInt::@constructor::new
          methods
            == @213
              reference: <testLibraryFragment>::@class::X3::@method::==
              enclosingElement3: <testLibraryFragment>::@class::X3
              parameters
                requiredPositional other @216
                  type: int
              returnType: bool
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/nullSafe.dart
      classes
        class X1 @30
          reference: <testLibraryFragment>::@class::X1
          element: <testLibraryFragment>::@class::X1
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::X1::@constructor::new
              element: <none>
              superConstructor: package:test/nullSafe.dart::<fragment>::@class::NullSafeDefault::@constructor::new
          methods
            == @74
              reference: <testLibraryFragment>::@class::X1::@method::==
              element: <none>
              parameters
                other @77
                  element: <none>
        class X2 @102
          reference: <testLibraryFragment>::@class::X2
          element: <testLibraryFragment>::@class::X2
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::X2::@constructor::new
              element: <none>
              superConstructor: package:test/nullSafe.dart::<fragment>::@class::NullSafeObject::@constructor::new
          methods
            == @145
              reference: <testLibraryFragment>::@class::X2::@method::==
              element: <none>
              parameters
                other @148
                  element: <none>
        class X3 @173
          reference: <testLibraryFragment>::@class::X3
          element: <testLibraryFragment>::@class::X3
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::X3::@constructor::new
              element: <none>
              superConstructor: package:test/nullSafe.dart::<fragment>::@class::NullSafeInt::@constructor::new
          methods
            == @213
              reference: <testLibraryFragment>::@class::X3::@method::==
              element: <none>
              parameters
                other @216
                  element: <none>
  classes
    class X1
      firstFragment: <testLibraryFragment>::@class::X1
      supertype: NullSafeDefault
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::X1::@constructor::new
          superConstructor: <none>
      methods
        ==
          firstFragment: <testLibraryFragment>::@class::X1::@method::==
          parameters
            requiredPositional other
              type: Object
    class X2
      firstFragment: <testLibraryFragment>::@class::X2
      supertype: NullSafeObject
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::X2::@constructor::new
          superConstructor: <none>
      methods
        ==
          firstFragment: <testLibraryFragment>::@class::X2::@method::==
          parameters
            requiredPositional other
              type: Object
    class X3
      firstFragment: <testLibraryFragment>::@class::X3
      supertype: NullSafeInt
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::X3::@constructor::new
          superConstructor: <none>
      methods
        ==
          firstFragment: <testLibraryFragment>::@class::X3::@method::==
          parameters
            requiredPositional other
              type: int
''');
  }

  test_instantiateToBounds_boundRefersToEarlierTypeArgument() async {
    var library = await buildLibrary('''
class C<S extends num, T extends C<S, T>> {}
C c;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        notSimplyBounded class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant S @8
              bound: num
              defaultType: num
            covariant T @23
              bound: C<S, T>
              defaultType: C<num, dynamic>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static c @47
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C<num, C<num, dynamic>>
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C<num, C<num, dynamic>>
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C<num, C<num, dynamic>>
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
            S @8
              element: <none>
            T @23
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      topLevelVariables
        c @47
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
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        S
          bound: num
        T
          bound: C<S, T>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C<num, C<num, dynamic>>
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
  setters
    synthetic static set c=
      firstFragment: <testLibraryFragment>::@setter::c
      parameters
        requiredPositional _c
          type: C<num, C<num, dynamic>>
''');
  }

  test_instantiateToBounds_boundRefersToItself() async {
    var library = await buildLibrary('''
class C<T extends C<T>> {}
C c;
var c2 = new C();
class B {
  var c3 = new C();
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
        notSimplyBounded class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              bound: C<T>
              defaultType: C<dynamic>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
        class B @56
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          fields
            c3 @66
              reference: <testLibraryFragment>::@class::B::@field::c3
              enclosingElement3: <testLibraryFragment>::@class::B
              type: C<C<Object?>>
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
          accessors
            synthetic get c3 @-1
              reference: <testLibraryFragment>::@class::B::@getter::c3
              enclosingElement3: <testLibraryFragment>::@class::B
              returnType: C<C<Object?>>
            synthetic set c3= @-1
              reference: <testLibraryFragment>::@class::B::@setter::c3
              enclosingElement3: <testLibraryFragment>::@class::B
              parameters
                requiredPositional _c3 @-1
                  type: C<C<Object?>>
              returnType: void
      topLevelVariables
        static c @29
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C<C<dynamic>>
        static c2 @36
          reference: <testLibraryFragment>::@topLevelVariable::c2
          enclosingElement3: <testLibraryFragment>
          type: C<C<Object?>>
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C<C<dynamic>>
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C<C<dynamic>>
          returnType: void
        synthetic static get c2 @-1
          reference: <testLibraryFragment>::@getter::c2
          enclosingElement3: <testLibraryFragment>
          returnType: C<C<Object?>>
        synthetic static set c2= @-1
          reference: <testLibraryFragment>::@setter::c2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c2 @-1
              type: C<C<Object?>>
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
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
        class B @56
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          fields
            c3 @66
              reference: <testLibraryFragment>::@class::B::@field::c3
              element: <none>
              getter2: <testLibraryFragment>::@class::B::@getter::c3
              setter2: <testLibraryFragment>::@class::B::@setter::c3
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
          getters
            get c3 @-1
              reference: <testLibraryFragment>::@class::B::@getter::c3
              element: <none>
          setters
            set c3= @-1
              reference: <testLibraryFragment>::@class::B::@setter::c3
              element: <none>
              parameters
                _c3 @-1
                  element: <none>
      topLevelVariables
        c @29
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <none>
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        c2 @36
          reference: <testLibraryFragment>::@topLevelVariable::c2
          element: <none>
          getter2: <testLibraryFragment>::@getter::c2
          setter2: <testLibraryFragment>::@setter::c2
      getters
        get c @-1
          reference: <testLibraryFragment>::@getter::c
          element: <none>
        get c2 @-1
          reference: <testLibraryFragment>::@getter::c2
          element: <none>
      setters
        set c= @-1
          reference: <testLibraryFragment>::@setter::c
          element: <none>
          parameters
            _c @-1
              element: <none>
        set c2= @-1
          reference: <testLibraryFragment>::@setter::c2
          element: <none>
          parameters
            _c2 @-1
              element: <none>
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: C<T>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        c3
          firstFragment: <testLibraryFragment>::@class::B::@field::c3
          type: C<C<Object?>>
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      getters
        synthetic get c3
          firstFragment: <testLibraryFragment>::@class::B::@getter::c3
      setters
        synthetic set c3=
          firstFragment: <testLibraryFragment>::@class::B::@setter::c3
          parameters
            requiredPositional _c3
              type: C<C<Object?>>
  topLevelVariables
    c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C<C<dynamic>>
      getter: <none>
      setter: <none>
    c2
      firstFragment: <testLibraryFragment>::@topLevelVariable::c2
      type: C<C<Object?>>
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
    synthetic static get c2
      firstFragment: <testLibraryFragment>::@getter::c2
  setters
    synthetic static set c=
      firstFragment: <testLibraryFragment>::@setter::c
      parameters
        requiredPositional _c
          type: C<C<dynamic>>
    synthetic static set c2=
      firstFragment: <testLibraryFragment>::@setter::c2
      parameters
        requiredPositional _c2
          type: C<C<Object?>>
''');
  }

  test_instantiateToBounds_boundRefersToLaterTypeArgument() async {
    var library = await buildLibrary('''
class C<T extends C<T, U>, U extends num> {}
C c;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        notSimplyBounded class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              bound: C<T, U>
              defaultType: C<dynamic, num>
            covariant U @27
              bound: num
              defaultType: num
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static c @47
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C<C<dynamic, num>, num>
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: C<C<dynamic, num>, num>
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C<C<dynamic, num>, num>
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
            U @27
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      topLevelVariables
        c @47
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
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: C<T, U>
        U
          bound: num
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C<C<dynamic, num>, num>
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
  setters
    synthetic static set c=
      firstFragment: <testLibraryFragment>::@setter::c
      parameters
        requiredPositional _c
          type: C<C<dynamic, num>, num>
''');
  }

  test_instantiateToBounds_functionTypeAlias_reexported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class O {}
typedef T F<T extends O>(T p);
''');
    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart' show F;
''');
    var library = await buildLibrary('''
import 'b.dart';
class C {
  F f() => null;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/b.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/b.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class C @23
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            f @31
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: O Function(O)
                alias: package:test/a.dart::<fragment>::@typeAlias::F
                  typeArguments
                    O
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/b.dart
      classes
        class C @23
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          methods
            f @31
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <none>
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
''');
  }

  test_instantiateToBounds_functionTypeAlias_simple() async {
    var library = await buildLibrary('''
typedef F<T extends num>(T p);
F f;
''');
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
          typeParameters
            contravariant T @10
              bound: num
              defaultType: num
          aliasedType: dynamic Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional p @27
                type: T
            returnType: dynamic
      topLevelVariables
        static f @33
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: dynamic Function(num)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                num
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic Function(num)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                num
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: dynamic Function(num)
                alias: <testLibraryFragment>::@typeAlias::F
                  typeArguments
                    num
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
          typeParameters
            T @10
              element: <none>
      topLevelVariables
        f @33
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
      firstFragment: <testLibraryFragment>::@typeAlias::F
      typeParameters
        T
          bound: num
      aliasedType: dynamic Function(T)
  topLevelVariables
    f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function(num)
        alias: <testLibraryFragment>::@typeAlias::F
          typeArguments
            num
      getter: <none>
      setter: <none>
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f=
      firstFragment: <testLibraryFragment>::@setter::f
      parameters
        requiredPositional _f
          type: dynamic Function(num)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                num
''');
  }

  test_instantiateToBounds_genericFunctionAsBound() async {
    var library = await buildLibrary('''
class A<T> {}
class B<T extends int Function(), U extends A<T>> {}
B b;
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
        notSimplyBounded class B @20
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @22
              bound: int Function()
              defaultType: int Function()
            covariant U @48
              bound: A<T>
              defaultType: A<int Function()>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
      topLevelVariables
        static b @69
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: B<int Function(), A<int Function()>>
      accessors
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: B<int Function(), A<int Function()>>
        synthetic static set b= @-1
          reference: <testLibraryFragment>::@setter::b
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _b @-1
              type: B<int Function(), A<int Function()>>
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
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @20
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          typeParameters
            T @22
              element: <none>
            U @48
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
      topLevelVariables
        b @69
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <none>
          getter2: <testLibraryFragment>::@getter::b
          setter2: <testLibraryFragment>::@setter::b
      getters
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <none>
      setters
        set b= @-1
          reference: <testLibraryFragment>::@setter::b
          element: <none>
          parameters
            _b @-1
              element: <none>
  classes
    class A
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
          bound: int Function()
        U
          bound: A<T>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  topLevelVariables
    b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: B<int Function(), A<int Function()>>
      getter: <none>
      setter: <none>
  getters
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
  setters
    synthetic static set b=
      firstFragment: <testLibraryFragment>::@setter::b
      parameters
        requiredPositional _b
          type: B<int Function(), A<int Function()>>
''');
  }

  test_instantiateToBounds_genericTypeAlias_simple() async {
    var library = await buildLibrary('''
typedef F<T extends num> = S Function<S>(T p);
F f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @10
              bound: num
              defaultType: num
          aliasedType: S Function<S>(T)
          aliasedElement: GenericFunctionTypeElement
            typeParameters
              covariant S @38
            parameters
              requiredPositional p @43
                type: T
            returnType: S
      topLevelVariables
        static f @49
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: S Function<S>(num)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                num
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: S Function<S>(num)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                num
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: S Function<S>(num)
                alias: <testLibraryFragment>::@typeAlias::F
                  typeArguments
                    num
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
          typeParameters
            T @10
              element: <none>
      topLevelVariables
        f @49
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
      firstFragment: <testLibraryFragment>::@typeAlias::F
      typeParameters
        T
          bound: num
      aliasedType: S Function<S>(T)
  topLevelVariables
    f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: S Function<S>(num)
        alias: <testLibraryFragment>::@typeAlias::F
          typeArguments
            num
      getter: <none>
      setter: <none>
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f=
      firstFragment: <testLibraryFragment>::@setter::f
      parameters
        requiredPositional _f
          type: S Function<S>(num)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                num
''');
  }

  test_instantiateToBounds_issue38498() async {
    var library = await buildLibrary('''
class A<R extends B> {
  final values = <B>[];
}
class B<T extends num> {}
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
            covariant R @8
              bound: B<num>
              defaultType: B<num>
          fields
            final values @31
              reference: <testLibraryFragment>::@class::A::@field::values
              enclosingElement3: <testLibraryFragment>::@class::A
              type: List<B<num>>
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            synthetic get values @-1
              reference: <testLibraryFragment>::@class::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: List<B<num>>
        class B @55
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @57
              bound: num
              defaultType: num
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
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
            R @8
              element: <none>
          fields
            values @31
              reference: <testLibraryFragment>::@class::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::values
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          getters
            get values @-1
              reference: <testLibraryFragment>::@class::A::@getter::values
              element: <none>
        class B @55
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          typeParameters
            T @57
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        R
          bound: B<num>
      fields
        final values
          firstFragment: <testLibraryFragment>::@class::A::@field::values
          type: List<B<num>>
          getter: <none>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get values
          firstFragment: <testLibraryFragment>::@class::A::@getter::values
    class B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
          bound: num
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
''');
  }

  test_instantiateToBounds_simple() async {
    var library = await buildLibrary('''
class C<T extends num> {}
C c;
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
              bound: num
              defaultType: num
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
      topLevelVariables
        static c @28
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: C<num>
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
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @8
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      topLevelVariables
        c @28
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
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: num
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C<num>
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
  setters
    synthetic static set c=
      firstFragment: <testLibraryFragment>::@setter::c
      parameters
        requiredPositional _c
          type: C<num>
''');
  }

  test_invalid_importPrefix_asTypeArgument() async {
    var library = await buildLibrary('''
import 'dart:async' as ppp;
class C {
  List<ppp> v;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async as ppp @23
      enclosingElement3: <testLibraryFragment>
  prefixes
    ppp @23
      reference: <testLibraryFragment>::@prefix::ppp
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:async as ppp @23
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        ppp @23
          reference: <testLibraryFragment>::@prefix::ppp
          enclosingElement3: <testLibraryFragment>
      classes
        class C @34
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            v @50
              reference: <testLibraryFragment>::@class::C::@field::v
              enclosingElement3: <testLibraryFragment>::@class::C
              type: List<dynamic>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get v @-1
              reference: <testLibraryFragment>::@class::C::@getter::v
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: List<dynamic>
            synthetic set v= @-1
              reference: <testLibraryFragment>::@class::C::@setter::v
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _v @-1
                  type: List<dynamic>
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      prefixes
        ppp
          reference: <testLibraryFragment>::@prefix::ppp
      classes
        class C @34
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          fields
            v @50
              reference: <testLibraryFragment>::@class::C::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::v
              setter2: <testLibraryFragment>::@class::C::@setter::v
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
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
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        v
          firstFragment: <testLibraryFragment>::@class::C::@field::v
          type: List<dynamic>
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get v
          firstFragment: <testLibraryFragment>::@class::C::@getter::v
      setters
        synthetic set v=
          firstFragment: <testLibraryFragment>::@class::C::@setter::v
          parameters
            requiredPositional _v
              type: List<dynamic>
''');
  }

  test_invalid_nameConflict_imported() async {
    newFile('$testPackageLibPath/a.dart', 'V() {}');
    newFile('$testPackageLibPath/b.dart', 'V() {}');
    var library = await buildLibrary('''
import 'a.dart';
import 'b.dart';
foo([p = V]) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
    package:test/b.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
        package:test/b.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @34
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalPositional default p @39
              type: dynamic
              constantInitializer
                SimpleIdentifier
                  token: V @43
                  staticElement: <null>
                  staticType: InvalidType
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
        package:test/b.dart
      functions
        foo @34
          reference: <testLibraryFragment>::@function::foo
          element: <none>
          parameters
            default p @39
              element: <none>
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      parameters
        optionalPositional p
          type: dynamic
      returnType: dynamic
''');
  }

  test_invalid_nameConflict_imported_exported() async {
    newFile('$testPackageLibPath/a.dart', 'V() {}');
    newFile('$testPackageLibPath/b.dart', 'V() {}');
    newFile('$testPackageLibPath/c.dart', r'''
export 'a.dart';
export 'b.dart';
''');
    var library = await buildLibrary('''
import 'c.dart';
foo([p = V]) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/c.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/c.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @17
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalPositional default p @22
              type: dynamic
              constantInitializer
                SimpleIdentifier
                  token: V @26
                  staticElement: package:test/a.dart::<fragment>::@function::V
                  staticType: dynamic Function()
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/c.dart
      functions
        foo @17
          reference: <testLibraryFragment>::@function::foo
          element: <none>
          parameters
            default p @22
              element: <none>
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      parameters
        optionalPositional p
          type: dynamic
      returnType: dynamic
''');
  }

  test_invalid_nameConflict_local() async {
    var library = await buildLibrary('''
foo([p = V]) {}
V() {}
var V;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static V @27
          reference: <testLibraryFragment>::@topLevelVariable::V
          enclosingElement3: <testLibraryFragment>
          type: dynamic
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
      functions
        foo @0
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalPositional default p @5
              type: dynamic
              constantInitializer
                SimpleIdentifier
                  token: V @9
                  staticElement: <testLibraryFragment>::@getter::V
                  staticType: dynamic
          returnType: dynamic
        V @16
          reference: <testLibraryFragment>::@function::V
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        V @27
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <none>
          getter2: <testLibraryFragment>::@getter::V
          setter2: <testLibraryFragment>::@setter::V
      getters
        get V @-1
          reference: <testLibraryFragment>::@getter::V
          element: <none>
      setters
        set V= @-1
          reference: <testLibraryFragment>::@setter::V
          element: <none>
          parameters
            _V @-1
              element: <none>
      functions
        foo @0
          reference: <testLibraryFragment>::@function::foo
          element: <none>
          parameters
            default p @5
              element: <none>
        V @16
          reference: <testLibraryFragment>::@function::V
          element: <none>
  topLevelVariables
    V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: dynamic
      getter: <none>
      setter: <none>
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
  setters
    synthetic static set V=
      firstFragment: <testLibraryFragment>::@setter::V
      parameters
        requiredPositional _V
          type: dynamic
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      parameters
        optionalPositional p
          type: dynamic
      returnType: dynamic
    V
      firstFragment: <testLibraryFragment>::@function::V
      returnType: dynamic
''');
  }

  test_nameConflict_exportedAndLocal() async {
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    newFile('$testPackageLibPath/c.dart', '''
export 'a.dart';
class C {}
''');
    var library = await buildLibrary('''
import 'c.dart';
C v = null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/c.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/c.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static v @19
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: C
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/c.dart
      topLevelVariables
        v @19
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: C
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      firstFragment: <testLibraryFragment>::@setter::v
      parameters
        requiredPositional _v
          type: C
''');
  }

  test_nameConflict_exportedAndLocal_exported() async {
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    newFile('$testPackageLibPath/c.dart', '''
export 'a.dart';
class C {}
''');
    newFile('$testPackageLibPath/d.dart', 'export "c.dart";');
    var library = await buildLibrary('''
import 'd.dart';
C v = null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/d.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/d.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static v @19
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: C
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/d.dart
      topLevelVariables
        v @19
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: C
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      firstFragment: <testLibraryFragment>::@setter::v
      parameters
        requiredPositional _v
          type: C
''');
  }

  test_nameConflict_exportedAndParted() async {
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    newFile('$testPackageLibPath/b.dart', '''
part of lib;
class C {}
''');
    newFile('$testPackageLibPath/c.dart', '''
library lib;
export 'a.dart';
part 'b.dart';
''');
    var library = await buildLibrary('''
import 'c.dart';
C v = null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/c.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/c.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static v @19
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: C
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: C
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/c.dart
      topLevelVariables
        v @19
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: C
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      firstFragment: <testLibraryFragment>::@setter::v
      parameters
        requiredPositional _v
          type: C
''');
  }

  test_nested_generic_functions_in_generic_class_with_function_typed_params() async {
    var library = await buildLibrary('''
class C<T, U> {
  void g<V, W>() {
    void h<X, Y>(void p(T t, U u, V v, W w, X x, Y y)) {
    }
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
            covariant U @11
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            g @23
              reference: <testLibraryFragment>::@class::C::@method::g
              enclosingElement3: <testLibraryFragment>::@class::C
              typeParameters
                covariant V @25
                  defaultType: dynamic
                covariant W @28
                  defaultType: dynamic
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
          methods
            g @23
              reference: <testLibraryFragment>::@class::C::@method::g
              element: <none>
              typeParameters
                V @25
                  element: <none>
                W @28
                  element: <none>
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
        U
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        g
          firstFragment: <testLibraryFragment>::@class::C::@method::g
          typeParameters
            V
            W
''');
  }

  test_nested_generic_functions_in_generic_class_with_local_variables() async {
    var library = await buildLibrary('''
class C<T, U> {
  void g<V, W>() {
    void h<X, Y>() {
      T t;
      U u;
      V v;
      W w;
      X x;
      Y y;
    }
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
            covariant U @11
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            g @23
              reference: <testLibraryFragment>::@class::C::@method::g
              enclosingElement3: <testLibraryFragment>::@class::C
              typeParameters
                covariant V @25
                  defaultType: dynamic
                covariant W @28
                  defaultType: dynamic
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
          methods
            g @23
              reference: <testLibraryFragment>::@class::C::@method::g
              element: <none>
              typeParameters
                V @25
                  element: <none>
                W @28
                  element: <none>
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
        U
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        g
          firstFragment: <testLibraryFragment>::@class::C::@method::g
          typeParameters
            V
            W
''');
  }

  test_nested_generic_functions_with_function_typed_param() async {
    var library = await buildLibrary('''
void f<T, U>() {
  void g<V, W>() {
    void h<X, Y>(void p(T t, U u, V v, W w, X x, Y y)) {
    }
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
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
            covariant U @10
              defaultType: dynamic
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
          element: <none>
          typeParameters
            T @7
              element: <none>
            U @10
              element: <none>
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
        U
      returnType: void
''');
  }

  test_nested_generic_functions_with_local_variables() async {
    var library = await buildLibrary('''
void f<T, U>() {
  void g<V, W>() {
    void h<X, Y>() {
      T t;
      U u;
      V v;
      W w;
      X x;
      Y y;
    }
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
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
            covariant U @10
              defaultType: dynamic
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
          element: <none>
          typeParameters
            T @7
              element: <none>
            U @10
              element: <none>
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
        U
      returnType: void
''');
  }

  test_propagated_type_refers_to_closure() async {
    var library = await buildLibrary('''
void f() {
  var x = () => 0;
  var y = x;
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
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
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
          element: <none>
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: void
''');
  }

  test_syntheticFunctionType_genericClosure() async {
    var library = await buildLibrary('''
final v = f() ? <T>(T t) => 0 : <T>(T t) => 1;
bool f() => true;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static final v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int Function<T>(T)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int Function<T>(T)
      functions
        f @52
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          returnType: bool
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      functions
        f @52
          reference: <testLibraryFragment>::@function::f
          element: <none>
  topLevelVariables
    final v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function<T>(T)
      getter: <none>
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: bool
''');
  }

  test_syntheticFunctionType_genericClosure_inGenericFunction() async {
    var library = await buildLibrary('''
void f<T, U>(bool b) {
  final v = b ? <V>(T t, U u, V v) => 0 : <V>(T t, U u, V v) => 1;
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
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
            covariant U @10
              defaultType: dynamic
          parameters
            requiredPositional b @18
              type: bool
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
          element: <none>
          typeParameters
            T @7
              element: <none>
            U @10
              element: <none>
          parameters
            b @18
              element: <none>
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
        U
      parameters
        requiredPositional b
          type: bool
      returnType: void
''');
  }

  test_syntheticFunctionType_inGenericClass() async {
    var library = await buildLibrary('''
class C<T, U> {
  var v = f() ? (T t, U u) => 0 : (T t, U u) => 1;
}
bool f() => false;
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
            covariant U @11
              defaultType: dynamic
          fields
            v @22
              reference: <testLibraryFragment>::@class::C::@field::v
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int Function(T, U)
              shouldUseTypeForInitializerInference: false
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get v @-1
              reference: <testLibraryFragment>::@class::C::@getter::v
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int Function(T, U)
            synthetic set v= @-1
              reference: <testLibraryFragment>::@class::C::@setter::v
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _v @-1
                  type: int Function(T, U)
              returnType: void
      functions
        f @74
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          returnType: bool
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
          fields
            v @22
              reference: <testLibraryFragment>::@class::C::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::v
              setter2: <testLibraryFragment>::@class::C::@setter::v
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
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
      functions
        f @74
          reference: <testLibraryFragment>::@function::f
          element: <none>
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
        U
      fields
        v
          firstFragment: <testLibraryFragment>::@class::C::@field::v
          type: int Function(T, U)
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get v
          firstFragment: <testLibraryFragment>::@class::C::@getter::v
      setters
        synthetic set v=
          firstFragment: <testLibraryFragment>::@class::C::@setter::v
          parameters
            requiredPositional _v
              type: int Function(T, U)
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: bool
''');
  }

  test_syntheticFunctionType_inGenericFunction() async {
    var library = await buildLibrary('''
void f<T, U>(bool b) {
  var v = b ? (T t, U u) => 0 : (T t, U u) => 1;
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
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
            covariant U @10
              defaultType: dynamic
          parameters
            requiredPositional b @18
              type: bool
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
          element: <none>
          typeParameters
            T @7
              element: <none>
            U @10
              element: <none>
          parameters
            b @18
              element: <none>
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
        U
      parameters
        requiredPositional b
          type: bool
      returnType: void
''');
  }

  test_syntheticFunctionType_noArguments() async {
    var library = await buildLibrary('''
final v = f() ? () => 0 : () => 1;
bool f() => true;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static final v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int Function()
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int Function()
      functions
        f @40
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          returnType: bool
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      functions
        f @40
          reference: <testLibraryFragment>::@function::f
          element: <none>
  topLevelVariables
    final v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function()
      getter: <none>
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: bool
''');
  }

  test_syntheticFunctionType_withArguments() async {
    var library = await buildLibrary('''
final v = f() ? (int x, String y) => 0 : (int x, String y) => 1;
bool f() => true;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static final v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int Function(int, String)
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int Function(int, String)
      functions
        f @70
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          returnType: bool
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      functions
        f @70
          reference: <testLibraryFragment>::@function::f
          element: <none>
  topLevelVariables
    final v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function(int, String)
      getter: <none>
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: bool
''');
  }

  test_type_arguments_explicit_dynamic_dynamic() async {
    var library = await buildLibrary('Map<dynamic, dynamic> m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static m @22
          reference: <testLibraryFragment>::@topLevelVariable::m
          enclosingElement3: <testLibraryFragment>
          type: Map<dynamic, dynamic>
      accessors
        synthetic static get m @-1
          reference: <testLibraryFragment>::@getter::m
          enclosingElement3: <testLibraryFragment>
          returnType: Map<dynamic, dynamic>
        synthetic static set m= @-1
          reference: <testLibraryFragment>::@setter::m
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _m @-1
              type: Map<dynamic, dynamic>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        m @22
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      type: Map<dynamic, dynamic>
      getter: <none>
      setter: <none>
  getters
    synthetic static get m
      firstFragment: <testLibraryFragment>::@getter::m
  setters
    synthetic static set m=
      firstFragment: <testLibraryFragment>::@setter::m
      parameters
        requiredPositional _m
          type: Map<dynamic, dynamic>
''');
  }

  test_type_arguments_explicit_dynamic_int() async {
    var library = await buildLibrary('Map<dynamic, int> m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static m @18
          reference: <testLibraryFragment>::@topLevelVariable::m
          enclosingElement3: <testLibraryFragment>
          type: Map<dynamic, int>
      accessors
        synthetic static get m @-1
          reference: <testLibraryFragment>::@getter::m
          enclosingElement3: <testLibraryFragment>
          returnType: Map<dynamic, int>
        synthetic static set m= @-1
          reference: <testLibraryFragment>::@setter::m
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _m @-1
              type: Map<dynamic, int>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        m @18
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      type: Map<dynamic, int>
      getter: <none>
      setter: <none>
  getters
    synthetic static get m
      firstFragment: <testLibraryFragment>::@getter::m
  setters
    synthetic static set m=
      firstFragment: <testLibraryFragment>::@setter::m
      parameters
        requiredPositional _m
          type: Map<dynamic, int>
''');
  }

  test_type_arguments_explicit_String_dynamic() async {
    var library = await buildLibrary('Map<String, dynamic> m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static m @21
          reference: <testLibraryFragment>::@topLevelVariable::m
          enclosingElement3: <testLibraryFragment>
          type: Map<String, dynamic>
      accessors
        synthetic static get m @-1
          reference: <testLibraryFragment>::@getter::m
          enclosingElement3: <testLibraryFragment>
          returnType: Map<String, dynamic>
        synthetic static set m= @-1
          reference: <testLibraryFragment>::@setter::m
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _m @-1
              type: Map<String, dynamic>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        m @21
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      type: Map<String, dynamic>
      getter: <none>
      setter: <none>
  getters
    synthetic static get m
      firstFragment: <testLibraryFragment>::@getter::m
  setters
    synthetic static set m=
      firstFragment: <testLibraryFragment>::@setter::m
      parameters
        requiredPositional _m
          type: Map<String, dynamic>
''');
  }

  test_type_arguments_explicit_String_int() async {
    var library = await buildLibrary('Map<String, int> m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static m @17
          reference: <testLibraryFragment>::@topLevelVariable::m
          enclosingElement3: <testLibraryFragment>
          type: Map<String, int>
      accessors
        synthetic static get m @-1
          reference: <testLibraryFragment>::@getter::m
          enclosingElement3: <testLibraryFragment>
          returnType: Map<String, int>
        synthetic static set m= @-1
          reference: <testLibraryFragment>::@setter::m
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _m @-1
              type: Map<String, int>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        m @17
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      type: Map<String, int>
      getter: <none>
      setter: <none>
  getters
    synthetic static get m
      firstFragment: <testLibraryFragment>::@getter::m
  setters
    synthetic static set m=
      firstFragment: <testLibraryFragment>::@setter::m
      parameters
        requiredPositional _m
          type: Map<String, int>
''');
  }

  test_type_arguments_implicit() async {
    var library = await buildLibrary('Map m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static m @4
          reference: <testLibraryFragment>::@topLevelVariable::m
          enclosingElement3: <testLibraryFragment>
          type: Map<dynamic, dynamic>
      accessors
        synthetic static get m @-1
          reference: <testLibraryFragment>::@getter::m
          enclosingElement3: <testLibraryFragment>
          returnType: Map<dynamic, dynamic>
        synthetic static set m= @-1
          reference: <testLibraryFragment>::@setter::m
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _m @-1
              type: Map<dynamic, dynamic>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        m @4
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      type: Map<dynamic, dynamic>
      getter: <none>
      setter: <none>
  getters
    synthetic static get m
      firstFragment: <testLibraryFragment>::@getter::m
  setters
    synthetic static set m=
      firstFragment: <testLibraryFragment>::@setter::m
      parameters
        requiredPositional _m
          type: Map<dynamic, dynamic>
''');
  }

  test_type_dynamic() async {
    var library = await buildLibrary('dynamic d;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static d @8
          reference: <testLibraryFragment>::@topLevelVariable::d
          enclosingElement3: <testLibraryFragment>
          type: dynamic
      accessors
        synthetic static get d @-1
          reference: <testLibraryFragment>::@getter::d
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static set d= @-1
          reference: <testLibraryFragment>::@setter::d
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _d @-1
              type: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        d @8
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::d
      type: dynamic
      getter: <none>
      setter: <none>
  getters
    synthetic static get d
      firstFragment: <testLibraryFragment>::@getter::d
  setters
    synthetic static set d=
      firstFragment: <testLibraryFragment>::@setter::d
      parameters
        requiredPositional _d
          type: dynamic
''');
  }

  test_type_unresolved() async {
    var library = await buildLibrary('C c;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static c @2
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: InvalidType
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        c @2
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
  topLevelVariables
    c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: InvalidType
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
  setters
    synthetic static set c=
      firstFragment: <testLibraryFragment>::@setter::c
      parameters
        requiredPositional _c
          type: InvalidType
''');
  }

  test_type_unresolved_prefixed() async {
    var library = await buildLibrary('import "dart:core" as core; core.C c;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:core as core @22
      enclosingElement3: <testLibraryFragment>
  prefixes
    core @22
      reference: <testLibraryFragment>::@prefix::core
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:core as core @22
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        core @22
          reference: <testLibraryFragment>::@prefix::core
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @35
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement3: <testLibraryFragment>
          type: InvalidType
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement3: <testLibraryFragment>
          returnType: InvalidType
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: InvalidType
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:core
      prefixes
        core
          reference: <testLibraryFragment>::@prefix::core
      topLevelVariables
        c @35
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
  topLevelVariables
    c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: InvalidType
      getter: <none>
      setter: <none>
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
  setters
    synthetic static set c=
      firstFragment: <testLibraryFragment>::@setter::c
      parameters
        requiredPositional _c
          type: InvalidType
''');
  }

  // TODO(scheglov): This is duplicate.
  void _assertTypeStr(DartType type, String expected) {
    var typeStr = type.getDisplayString();
    expect(typeStr, expected);
  }
}

@reflectiveTest
class TypesElementTest_fromBytes extends TypesElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class TypesElementTest_keepLinking extends TypesElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
