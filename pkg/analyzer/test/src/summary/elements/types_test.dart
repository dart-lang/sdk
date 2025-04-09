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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
      functions
        main @18
          reference: <testLibraryFragment>::@function::main
          element: <testLibrary>::@function::main
          formalParameters
            f @25
              element: <testLibraryFragment>::@function::main::@parameter::f#element
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: dynamic Function(int)
  functions
    main
      reference: <testLibrary>::@function::main
      firstFragment: <testLibraryFragment>::@function::main
      formalParameters
        requiredPositional f
          type: dynamic Function(int)
            alias: <testLibrary>::@typeAlias::F
      returnType: dynamic
''');
  }

  test_futureOr() async {
    var library = await buildLibrary('import "dart:async"; FutureOr<int> x;');
    checkElementText(library, r'''
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
    x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: FutureOr<int>
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: FutureOr<int>
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: FutureOr<int>
      returnType: void
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        hasInitializer x @27
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SimpleIdentifier
              token: FutureOr @31
              element: dart:async::@class::FutureOr
              staticType: Type
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: Type
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: Type
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        hasInitializer x @52
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
        hasInitializer y @65
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
      functions
        f @35
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: FutureOr<int>
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
    hasInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      type: InvalidType
      getter: <testLibraryFragment>::@getter::y#element
      setter: <testLibraryFragment>::@setter::y#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: FutureOr<int>
    synthetic static get y
      firstFragment: <testLibraryFragment>::@getter::y
      returnType: InvalidType
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: FutureOr<int>
      returnType: void
    synthetic static set y
      firstFragment: <testLibraryFragment>::@setter::y
      formalParameters
        requiredPositional _y
          type: InvalidType
      returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
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
            m @30
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <testLibraryFragment>::@class::C::@method::m#element
              typeParameters
                V @32
                  element: V@32
                W @35
                  element: W@35
              formalParameters
                v @40
                  element: <testLibraryFragment>::@class::C::@method::m::@parameter::v#element
                w @45
                  element: <testLibraryFragment>::@class::C::@method::m::@parameter::w#element
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
      methods
        static m
          firstFragment: <testLibraryFragment>::@class::C::@method::m
          typeParameters
            V
            W
          formalParameters
            requiredPositional v
              type: V
            requiredPositional w
              type: W
          returnType: void
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
            call @17
              reference: <testLibraryFragment>::@class::C::@method::call
              element: <testLibraryFragment>::@class::C::@method::call#element
        class D @36
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          constructors
            const new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
              typeNameOffset: 48
              formalParameters
                c @52
                  element: <testLibraryFragment>::@class::D::@constructor::new::@parameter::c#element
            const named @83
              reference: <testLibraryFragment>::@class::D::@constructor::named
              element: <testLibraryFragment>::@class::D::@constructor::named#element
              typeName: D
              typeNameOffset: 81
              periodOffset: 82
              formalParameters
                f @105
                  element: <testLibraryFragment>::@class::D::@constructor::named::@parameter::f#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        call
          firstFragment: <testLibraryFragment>::@class::C::@method::call
          returnType: void
    class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
          formalParameters
            requiredPositional c
              type: C
          constantInitializers
            RedirectingConstructorInvocation
              thisKeyword: this @57
              period: . @61
              constructorName: SimpleIdentifier
                token: named @62
                element: <testLibraryFragment>::@class::D::@constructor::named#element
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @67
                arguments
                  ImplicitCallReference
                    expression: SimpleIdentifier
                      token: c @68
                      element: <testLibraryFragment>::@class::D::@constructor::new::@parameter::c#element
                      staticType: C
                    element: <testLibraryFragment>::@class::C::@method::call#element
                    staticType: void Function()
                rightParenthesis: ) @69
              element: <testLibraryFragment>::@class::D::@constructor::named#element
          redirectedConstructor: <testLibraryFragment>::@class::D::@constructor::named#element
        const named
          firstFragment: <testLibraryFragment>::@class::D::@constructor::named
          formalParameters
            requiredPositional f
              type: void Function()
''');
  }

  test_initializer_executable_with_return_type_from_closure() async {
    var library = await buildLibrary('var v = () => 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @4
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
      type: int Function()
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int Function()
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: int Function()
      returnType: void
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_dynamic() async {
    var library = await buildLibrary('var v = (f) async => await f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @4
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
      type: Future<dynamic> Function(dynamic)
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: Future<dynamic> Function(dynamic)
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: Future<dynamic> Function(dynamic)
      returnType: void
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        hasInitializer v @25
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
      type: Future<int> Function(Future<Future<Future<int>>>)
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: Future<int> Function(Future<Future<Future<int>>>)
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: Future<int> Function(Future<Future<Future<int>>>)
      returnType: void
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        hasInitializer v @25
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
      type: Future<int> Function(Future<int>)
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: Future<int> Function(Future<int>)
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: Future<int> Function(Future<int>)
      returnType: void
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        hasInitializer v @25
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
      type: Future<dynamic> Function(Future<dynamic>)
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: Future<dynamic> Function(Future<dynamic>)
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: Future<dynamic> Function(Future<dynamic>)
      returnType: void
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasInitializer v @16
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
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        hasInitializer v
          firstFragment: <testLibraryFragment>::@class::C::@field::v
          type: int Function()
          getter: <testLibraryFragment>::@class::C::@getter::v#element
          setter: <testLibraryFragment>::@class::C::@setter::v#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get v
          firstFragment: <testLibraryFragment>::@class::C::@getter::v
          returnType: int Function()
      setters
        synthetic set v
          firstFragment: <testLibraryFragment>::@class::C::@setter::v
          formalParameters
            requiredPositional _v
              type: int Function()
          returnType: void
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/nullSafe.dart
      classes
        class X1 @30
          reference: <testLibraryFragment>::@class::X1
          element: <testLibrary>::@class::X1
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::X1::@constructor::new
              element: <testLibraryFragment>::@class::X1::@constructor::new#element
              typeName: X1
          methods
            == @74
              reference: <testLibraryFragment>::@class::X1::@method::==
              element: <testLibraryFragment>::@class::X1::@method::==#element
              formalParameters
                other @77
                  element: <testLibraryFragment>::@class::X1::@method::==::@parameter::other#element
        class X2 @102
          reference: <testLibraryFragment>::@class::X2
          element: <testLibrary>::@class::X2
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::X2::@constructor::new
              element: <testLibraryFragment>::@class::X2::@constructor::new#element
              typeName: X2
          methods
            == @145
              reference: <testLibraryFragment>::@class::X2::@method::==
              element: <testLibraryFragment>::@class::X2::@method::==#element
              formalParameters
                other @148
                  element: <testLibraryFragment>::@class::X2::@method::==::@parameter::other#element
        class X3 @173
          reference: <testLibraryFragment>::@class::X3
          element: <testLibrary>::@class::X3
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::X3::@constructor::new
              element: <testLibraryFragment>::@class::X3::@constructor::new#element
              typeName: X3
          methods
            == @213
              reference: <testLibraryFragment>::@class::X3::@method::==
              element: <testLibraryFragment>::@class::X3::@method::==#element
              formalParameters
                other @216
                  element: <testLibraryFragment>::@class::X3::@method::==::@parameter::other#element
  classes
    class X1
      reference: <testLibrary>::@class::X1
      firstFragment: <testLibraryFragment>::@class::X1
      supertype: NullSafeDefault
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::X1::@constructor::new
          superConstructor: package:test/nullSafe.dart::<fragment>::@class::NullSafeDefault::@constructor::new#element
      methods
        ==
          firstFragment: <testLibraryFragment>::@class::X1::@method::==
          formalParameters
            requiredPositional hasImplicitType other
              type: Object
          returnType: bool
    class X2
      reference: <testLibrary>::@class::X2
      firstFragment: <testLibraryFragment>::@class::X2
      supertype: NullSafeObject
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::X2::@constructor::new
          superConstructor: package:test/nullSafe.dart::<fragment>::@class::NullSafeObject::@constructor::new#element
      methods
        ==
          firstFragment: <testLibraryFragment>::@class::X2::@method::==
          formalParameters
            requiredPositional hasImplicitType other
              type: Object
          returnType: bool
    class X3
      reference: <testLibrary>::@class::X3
      firstFragment: <testLibraryFragment>::@class::X3
      supertype: NullSafeInt
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::X3::@constructor::new
          superConstructor: package:test/nullSafe.dart::<fragment>::@class::NullSafeInt::@constructor::new#element
      methods
        ==
          firstFragment: <testLibraryFragment>::@class::X3::@method::==
          formalParameters
            requiredPositional hasImplicitType other
              type: int
          returnType: bool
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            S @8
              element: S@8
            T @23
              element: T@23
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      topLevelVariables
        c @47
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
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
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
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C<num, C<num, dynamic>>
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C<num, C<num, dynamic>>
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C<num, C<num, dynamic>>
      returnType: void
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
        class B @56
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          fields
            hasInitializer c3 @66
              reference: <testLibraryFragment>::@class::B::@field::c3
              element: <testLibraryFragment>::@class::B::@field::c3#element
              getter2: <testLibraryFragment>::@class::B::@getter::c3
              setter2: <testLibraryFragment>::@class::B::@setter::c3
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
          getters
            synthetic get c3
              reference: <testLibraryFragment>::@class::B::@getter::c3
              element: <testLibraryFragment>::@class::B::@getter::c3#element
          setters
            synthetic set c3
              reference: <testLibraryFragment>::@class::B::@setter::c3
              element: <testLibraryFragment>::@class::B::@setter::c3#element
              formalParameters
                _c3
                  element: <testLibraryFragment>::@class::B::@setter::c3::@parameter::_c3#element
      topLevelVariables
        c @29
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        hasInitializer c2 @36
          reference: <testLibraryFragment>::@topLevelVariable::c2
          element: <testLibrary>::@topLevelVariable::c2
          getter2: <testLibraryFragment>::@getter::c2
          setter2: <testLibraryFragment>::@setter::c2
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get c2
          reference: <testLibraryFragment>::@getter::c2
          element: <testLibraryFragment>::@getter::c2#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set c2
          reference: <testLibraryFragment>::@setter::c2
          element: <testLibraryFragment>::@setter::c2#element
          formalParameters
            _c2
              element: <testLibraryFragment>::@setter::c2::@parameter::_c2#element
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: C<T>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        hasInitializer c3
          firstFragment: <testLibraryFragment>::@class::B::@field::c3
          type: C<C<Object?>>
          getter: <testLibraryFragment>::@class::B::@getter::c3#element
          setter: <testLibraryFragment>::@class::B::@setter::c3#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      getters
        synthetic get c3
          firstFragment: <testLibraryFragment>::@class::B::@getter::c3
          returnType: C<C<Object?>>
      setters
        synthetic set c3
          firstFragment: <testLibraryFragment>::@class::B::@setter::c3
          formalParameters
            requiredPositional _c3
              type: C<C<Object?>>
          returnType: void
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C<C<dynamic>>
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    hasInitializer c2
      reference: <testLibrary>::@topLevelVariable::c2
      firstFragment: <testLibraryFragment>::@topLevelVariable::c2
      type: C<C<Object?>>
      getter: <testLibraryFragment>::@getter::c2#element
      setter: <testLibraryFragment>::@setter::c2#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C<C<dynamic>>
    synthetic static get c2
      firstFragment: <testLibraryFragment>::@getter::c2
      returnType: C<C<Object?>>
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C<C<dynamic>>
      returnType: void
    synthetic static set c2
      firstFragment: <testLibraryFragment>::@setter::c2
      formalParameters
        requiredPositional _c2
          type: C<C<Object?>>
      returnType: void
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
            U @27
              element: U@27
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
      topLevelVariables
        c @47
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
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
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
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C<C<dynamic, num>, num>
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C<C<dynamic, num>, num>
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C<C<dynamic, num>, num>
      returnType: void
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/b.dart
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
            f @31
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <testLibraryFragment>::@class::C::@method::f#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          returnType: O Function(O)
            alias: package:test/a.dart::@typeAlias::F
              typeArguments
                O
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
          typeParameters
            T @10
              element: T@10
      topLevelVariables
        f @33
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
          bound: num
      aliasedType: dynamic Function(T)
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: dynamic Function(num)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            num
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: dynamic Function(num)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            num
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: dynamic Function(num)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                num
      returnType: void
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
        class B @20
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T @22
              element: T@22
            U @48
              element: U@48
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
      topLevelVariables
        b @69
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
          setter2: <testLibraryFragment>::@setter::b
      getters
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
      setters
        synthetic set b
          reference: <testLibraryFragment>::@setter::b
          element: <testLibraryFragment>::@setter::b#element
          formalParameters
            _b
              element: <testLibraryFragment>::@setter::b::@parameter::_b#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    notSimplyBounded class B
      reference: <testLibrary>::@class::B
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
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: B<int Function(), A<int Function()>>
      getter: <testLibraryFragment>::@getter::b#element
      setter: <testLibraryFragment>::@setter::b#element
  getters
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: B<int Function(), A<int Function()>>
  setters
    synthetic static set b
      firstFragment: <testLibraryFragment>::@setter::b
      formalParameters
        requiredPositional _b
          type: B<int Function(), A<int Function()>>
      returnType: void
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
          typeParameters
            T @10
              element: T@10
      topLevelVariables
        f @49
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
          bound: num
      aliasedType: S Function<S>(T)
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: S Function<S>(num)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            num
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: S Function<S>(num)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            num
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: S Function<S>(num)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                num
      returnType: void
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            R @8
              element: R@8
          fields
            hasInitializer values @31
              reference: <testLibraryFragment>::@class::A::@field::values
              element: <testLibraryFragment>::@class::A::@field::values#element
              getter2: <testLibraryFragment>::@class::A::@getter::values
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          getters
            synthetic get values
              reference: <testLibraryFragment>::@class::A::@getter::values
              element: <testLibraryFragment>::@class::A::@getter::values#element
        class B @55
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T @57
              element: T@57
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        R
          bound: B<num>
      fields
        final hasInitializer values
          firstFragment: <testLibraryFragment>::@class::A::@field::values
          type: List<B<num>>
          getter: <testLibraryFragment>::@class::A::@getter::values#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get values
          firstFragment: <testLibraryFragment>::@class::A::@getter::values
          returnType: List<B<num>>
    class B
      reference: <testLibrary>::@class::B
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
      topLevelVariables
        c @28
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
          bound: num
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  topLevelVariables
    c
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as ppp @23
      prefixes
        <testLibraryFragment>::@prefix2::ppp
          fragments: @23
      classes
        class C @34
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            v @50
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
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        v
          firstFragment: <testLibraryFragment>::@class::C::@field::v
          type: List<dynamic>
          getter: <testLibraryFragment>::@class::C::@getter::v#element
          setter: <testLibraryFragment>::@class::C::@setter::v#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get v
          firstFragment: <testLibraryFragment>::@class::C::@getter::v
          returnType: List<dynamic>
      setters
        synthetic set v
          firstFragment: <testLibraryFragment>::@class::C::@setter::v
          formalParameters
            requiredPositional _v
              type: List<dynamic>
          returnType: void
''');
  }

  test_invalid_nameConflict_imported() async {
    if (!keepLinkingLibraries) return;

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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
        package:test/b.dart
      functions
        foo @34
          reference: <testLibraryFragment>::@function::foo
          element: <testLibrary>::@function::foo
          formalParameters
            default p @39
              element: <testLibraryFragment>::@function::foo::@parameter::p#element
              initializer: expression_0
                SimpleIdentifier
                  token: V @43
                  element: multiplyDefinedElement
                    package:test/a.dart::@function::V
                    package:test/b.dart::@function::V
                  staticType: InvalidType
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
      formalParameters
        optionalPositional hasImplicitType p
          type: dynamic
          constantInitializer
            expression: expression_0
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/c.dart
      functions
        foo @17
          reference: <testLibraryFragment>::@function::foo
          element: <testLibrary>::@function::foo
          formalParameters
            default p @22
              element: <testLibraryFragment>::@function::foo::@parameter::p#element
              initializer: expression_0
                SimpleIdentifier
                  token: V @26
                  element: package:test/a.dart::@function::V
                  staticType: dynamic Function()
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
      formalParameters
        optionalPositional hasImplicitType p
          type: dynamic
          constantInitializer
            expression: expression_0
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        V @27
          reference: <testLibraryFragment>::@topLevelVariable::V
          element: <testLibrary>::@topLevelVariable::V
          getter2: <testLibraryFragment>::@getter::V
          setter2: <testLibraryFragment>::@setter::V
      getters
        synthetic get V
          reference: <testLibraryFragment>::@getter::V
          element: <testLibraryFragment>::@getter::V#element
      setters
        synthetic set V
          reference: <testLibraryFragment>::@setter::V
          element: <testLibraryFragment>::@setter::V#element
          formalParameters
            _V
              element: <testLibraryFragment>::@setter::V::@parameter::_V#element
      functions
        foo @0
          reference: <testLibraryFragment>::@function::foo
          element: <testLibrary>::@function::foo
          formalParameters
            default p @5
              element: <testLibraryFragment>::@function::foo::@parameter::p#element
              initializer: expression_0
                SimpleIdentifier
                  token: V @9
                  element: <testLibraryFragment>::@getter::V#element
                  staticType: dynamic
        V @16
          reference: <testLibraryFragment>::@function::V
          element: <testLibrary>::@function::V
  topLevelVariables
    V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: <testLibraryFragment>::@topLevelVariable::V
      type: dynamic
      getter: <testLibraryFragment>::@getter::V#element
      setter: <testLibraryFragment>::@setter::V#element
  getters
    synthetic static get V
      firstFragment: <testLibraryFragment>::@getter::V
      returnType: dynamic
  setters
    synthetic static set V
      firstFragment: <testLibraryFragment>::@setter::V
      formalParameters
        requiredPositional _V
          type: dynamic
      returnType: void
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
      formalParameters
        optionalPositional hasImplicitType p
          type: dynamic
          constantInitializer
            expression: expression_0
      returnType: dynamic
    V
      reference: <testLibrary>::@function::V
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/c.dart
      topLevelVariables
        hasInitializer v @19
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
      type: C
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: C
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: C
      returnType: void
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/d.dart
      topLevelVariables
        hasInitializer v @19
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
      type: C
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: C
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: C
      returnType: void
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/c.dart
      topLevelVariables
        hasInitializer v @19
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
      type: C
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: C
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: C
      returnType: void
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
            g @23
              reference: <testLibraryFragment>::@class::C::@method::g
              element: <testLibraryFragment>::@class::C::@method::g#element
              typeParameters
                V @25
                  element: V@25
                W @28
                  element: W@28
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
      methods
        g
          firstFragment: <testLibraryFragment>::@class::C::@method::g
          typeParameters
            V
            W
          returnType: void
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
            g @23
              reference: <testLibraryFragment>::@class::C::@method::g
              element: <testLibraryFragment>::@class::C::@method::g#element
              typeParameters
                V @25
                  element: V@25
                W @28
                  element: W@28
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
      methods
        g
          firstFragment: <testLibraryFragment>::@class::C::@method::g
          typeParameters
            V
            W
          returnType: void
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @7
              element: T@7
            U @10
              element: U@10
  functions
    f
      reference: <testLibrary>::@function::f
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @7
              element: T@7
            U @10
              element: U@10
  functions
    f
      reference: <testLibrary>::@function::f
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      functions
        f @52
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  topLevelVariables
    final hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function<T>(T)
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int Function<T>(T)
  functions
    f
      reference: <testLibrary>::@function::f
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @7
              element: T@7
            U @10
              element: U@10
          formalParameters
            b @18
              element: <testLibraryFragment>::@function::f::@parameter::b#element
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
        U
      formalParameters
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
          fields
            hasInitializer v @22
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
      functions
        f @74
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
        U
      fields
        hasInitializer v
          firstFragment: <testLibraryFragment>::@class::C::@field::v
          hasEnclosingTypeParameterReference: true
          type: int Function(T, U)
          getter: <testLibraryFragment>::@class::C::@getter::v#element
          setter: <testLibraryFragment>::@class::C::@setter::v#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get v
          firstFragment: <testLibraryFragment>::@class::C::@getter::v
          hasEnclosingTypeParameterReference: true
          returnType: int Function(T, U)
      setters
        synthetic set v
          firstFragment: <testLibraryFragment>::@class::C::@setter::v
          hasEnclosingTypeParameterReference: true
          formalParameters
            requiredPositional _v
              type: int Function(T, U)
          returnType: void
  functions
    f
      reference: <testLibrary>::@function::f
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @7
              element: T@7
            U @10
              element: U@10
          formalParameters
            b @18
              element: <testLibraryFragment>::@function::f::@parameter::b#element
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
        U
      formalParameters
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      functions
        f @40
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  topLevelVariables
    final hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function()
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int Function()
  functions
    f
      reference: <testLibrary>::@function::f
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
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      functions
        f @70
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  topLevelVariables
    final hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function(int, String)
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int Function(int, String)
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: bool
''');
  }

  test_type_arguments_explicit_dynamic_dynamic() async {
    var library = await buildLibrary('Map<dynamic, dynamic> m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        m @22
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
    m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      type: Map<dynamic, dynamic>
      getter: <testLibraryFragment>::@getter::m#element
      setter: <testLibraryFragment>::@setter::m#element
  getters
    synthetic static get m
      firstFragment: <testLibraryFragment>::@getter::m
      returnType: Map<dynamic, dynamic>
  setters
    synthetic static set m
      firstFragment: <testLibraryFragment>::@setter::m
      formalParameters
        requiredPositional _m
          type: Map<dynamic, dynamic>
      returnType: void
''');
  }

  test_type_arguments_explicit_dynamic_int() async {
    var library = await buildLibrary('Map<dynamic, int> m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        m @18
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
    m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      type: Map<dynamic, int>
      getter: <testLibraryFragment>::@getter::m#element
      setter: <testLibraryFragment>::@setter::m#element
  getters
    synthetic static get m
      firstFragment: <testLibraryFragment>::@getter::m
      returnType: Map<dynamic, int>
  setters
    synthetic static set m
      firstFragment: <testLibraryFragment>::@setter::m
      formalParameters
        requiredPositional _m
          type: Map<dynamic, int>
      returnType: void
''');
  }

  test_type_arguments_explicit_String_dynamic() async {
    var library = await buildLibrary('Map<String, dynamic> m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        m @21
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
    m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      type: Map<String, dynamic>
      getter: <testLibraryFragment>::@getter::m#element
      setter: <testLibraryFragment>::@setter::m#element
  getters
    synthetic static get m
      firstFragment: <testLibraryFragment>::@getter::m
      returnType: Map<String, dynamic>
  setters
    synthetic static set m
      firstFragment: <testLibraryFragment>::@setter::m
      formalParameters
        requiredPositional _m
          type: Map<String, dynamic>
      returnType: void
''');
  }

  test_type_arguments_explicit_String_int() async {
    var library = await buildLibrary('Map<String, int> m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        m @17
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
    m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      type: Map<String, int>
      getter: <testLibraryFragment>::@getter::m#element
      setter: <testLibraryFragment>::@setter::m#element
  getters
    synthetic static get m
      firstFragment: <testLibraryFragment>::@getter::m
      returnType: Map<String, int>
  setters
    synthetic static set m
      firstFragment: <testLibraryFragment>::@setter::m
      formalParameters
        requiredPositional _m
          type: Map<String, int>
      returnType: void
''');
  }

  test_type_arguments_implicit() async {
    var library = await buildLibrary('Map m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        m @4
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
    m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: <testLibraryFragment>::@topLevelVariable::m
      type: Map<dynamic, dynamic>
      getter: <testLibraryFragment>::@getter::m#element
      setter: <testLibraryFragment>::@setter::m#element
  getters
    synthetic static get m
      firstFragment: <testLibraryFragment>::@getter::m
      returnType: Map<dynamic, dynamic>
  setters
    synthetic static set m
      firstFragment: <testLibraryFragment>::@setter::m
      formalParameters
        requiredPositional _m
          type: Map<dynamic, dynamic>
      returnType: void
''');
  }

  test_type_dynamic() async {
    var library = await buildLibrary('dynamic d;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        d @8
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
      type: dynamic
      getter: <testLibraryFragment>::@getter::d#element
      setter: <testLibraryFragment>::@setter::d#element
  getters
    synthetic static get d
      firstFragment: <testLibraryFragment>::@getter::d
      returnType: dynamic
  setters
    synthetic static set d
      firstFragment: <testLibraryFragment>::@setter::d
      formalParameters
        requiredPositional _d
          type: dynamic
      returnType: void
''');
  }

  test_type_unresolved() async {
    var library = await buildLibrary('C c;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        c @2
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
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: InvalidType
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: InvalidType
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: InvalidType
      returnType: void
''');
  }

  test_type_unresolved_prefixed() async {
    var library = await buildLibrary('import "dart:core" as core; core.C c;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:core as core @22
      prefixes
        <testLibraryFragment>::@prefix2::core
          fragments: @22
      topLevelVariables
        c @35
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
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: InvalidType
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: InvalidType
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: InvalidType
      returnType: void
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
