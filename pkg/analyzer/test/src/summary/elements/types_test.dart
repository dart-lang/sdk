// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
      functions
        #F2 main (nameOffset:18) (firstTokenOffset:18) (offset:18)
          element: <testLibrary>::@function::main
          formalParameters
            #F3 f (nameOffset:25) (firstTokenOffset:23) (offset:25)
              element: <testLibrary>::@function::main::@formalParameter::f
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: dynamic Function(int)
  functions
    main
      reference: <testLibrary>::@function::main
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional f
          firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        #F1 x (nameOffset:35) (firstTokenOffset:35) (offset:35)
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
    x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: FutureOr<int>
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: FutureOr<int>
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: FutureOr<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
    var variables = library.topLevelVariables;
    expect(variables, hasLength(1));
    _assertTypeStr(variables[0].type, 'FutureOr<int>');
  }

  test_futureOr_const() async {
    var library = await buildLibrary(
      'import "dart:async"; const x = FutureOr;',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        #F1 hasInitializer x (nameOffset:27) (firstTokenOffset:27) (offset:27)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            SimpleIdentifier
              token: FutureOr @31
              element: dart:async::@class::FutureOr
              staticType: Type
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Type
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Type
      variable: <testLibrary>::@topLevelVariable::x
''');
    var variables = library.topLevelVariables;
    expect(variables, hasLength(1));
    var x = variables[0];
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        #F1 hasInitializer x (nameOffset:52) (firstTokenOffset:52) (offset:52)
          element: <testLibrary>::@topLevelVariable::x
        #F2 hasInitializer y (nameOffset:65) (firstTokenOffset:65) (offset:65)
          element: <testLibrary>::@topLevelVariable::y
      getters
        #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@getter::x
        #F4 synthetic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
          element: <testLibrary>::@getter::y
      setters
        #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@setter::x
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@setter::x::@formalParameter::value
        #F7 synthetic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
          element: <testLibrary>::@setter::y
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
              element: <testLibrary>::@setter::y::@formalParameter::value
      functions
        #F9 f (nameOffset:35) (firstTokenOffset:21) (offset:35)
          element: <testLibrary>::@function::f
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: FutureOr<int>
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
    hasInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F2
      type: InvalidType
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F3
      returnType: FutureOr<int>
      variable: <testLibrary>::@topLevelVariable::x
    synthetic static y
      reference: <testLibrary>::@getter::y
      firstFragment: #F4
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::y
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: FutureOr<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
    synthetic static y
      reference: <testLibrary>::@setter::y
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: InvalidType
      returnType: void
      variable: <testLibrary>::@topLevelVariable::y
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F9
      returnType: FutureOr<int>
''');
    var variables = library.topLevelVariables;
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
            #F5 m (nameOffset:30) (firstTokenOffset:18) (offset:30)
              element: <testLibrary>::@class::C::@method::m
              typeParameters
                #F6 V (nameOffset:32) (firstTokenOffset:32) (offset:32)
                  element: #E2 V
                #F7 W (nameOffset:35) (firstTokenOffset:35) (offset:35)
                  element: #E3 W
              formalParameters
                #F8 v (nameOffset:40) (firstTokenOffset:38) (offset:40)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::v
                #F9 w (nameOffset:45) (firstTokenOffset:43) (offset:45)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::w
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
      methods
        static m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F5
          typeParameters
            #E2 V
              firstFragment: #F6
            #E3 W
              firstFragment: #F7
          formalParameters
            #E4 requiredPositional v
              firstFragment: #F8
              type: V
            #E5 requiredPositional w
              firstFragment: #F9
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
            #F3 call (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::C::@method::call
        #F4 class D (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::D
          constructors
            #F5 const new (nameOffset:<null>) (firstTokenOffset:42) (offset:48)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
              typeNameOffset: 48
              formalParameters
                #F6 c (nameOffset:52) (firstTokenOffset:50) (offset:52)
                  element: <testLibrary>::@class::D::@constructor::new::@formalParameter::c
            #F7 const named (nameOffset:83) (firstTokenOffset:75) (offset:83)
              element: <testLibrary>::@class::D::@constructor::named
              typeName: D
              typeNameOffset: 81
              periodOffset: 82
              formalParameters
                #F8 f (nameOffset:105) (firstTokenOffset:89) (offset:105)
                  element: <testLibrary>::@class::D::@constructor::named::@formalParameter::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        call
          reference: <testLibrary>::@class::C::@method::call
          firstFragment: #F3
          returnType: void
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      constructors
        const new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional c
              firstFragment: #F6
              type: C
          constantInitializers
            RedirectingConstructorInvocation
              thisKeyword: this @57
              period: . @61
              constructorName: SimpleIdentifier
                token: named @62
                element: <testLibrary>::@class::D::@constructor::named
                staticType: null
              argumentList: ArgumentList
                leftParenthesis: ( @67
                arguments
                  ImplicitCallReference
                    expression: SimpleIdentifier
                      token: c @68
                      element: <testLibrary>::@class::D::@constructor::new::@formalParameter::c
                      staticType: C
                    element: <testLibrary>::@class::C::@method::call
                    staticType: void Function()
                rightParenthesis: ) @69
              element: <testLibrary>::@class::D::@constructor::named
          redirectedConstructor: <testLibrary>::@class::D::@constructor::named
        const named
          reference: <testLibrary>::@class::D::@constructor::named
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional f
              firstFragment: #F8
              type: void Function()
''');
  }

  test_initializer_executable_with_return_type_from_closure() async {
    var library = await buildLibrary('var v = () => 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer v (nameOffset:4) (firstTokenOffset:4) (offset:4)
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
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int Function()
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int Function()
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_dynamic() async {
    var library = await buildLibrary('var v = (f) async => await f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer v (nameOffset:4) (firstTokenOffset:4) (offset:4)
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
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: Future<dynamic> Function(dynamic)
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: Future<dynamic> Function(dynamic)
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Future<dynamic> Function(dynamic)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        #F1 hasInitializer v (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: Future<int> Function(Future<Future<Future<int>>>)
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: Future<int> Function(Future<Future<Future<int>>>)
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Future<int> Function(Future<Future<Future<int>>>)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        #F1 hasInitializer v (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: Future<int> Function(Future<int>)
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: Future<int> Function(Future<int>)
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Future<int> Function(Future<int>)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        #F1 hasInitializer v (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: Future<dynamic> Function(Future<dynamic>)
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: Future<dynamic> Function(Future<dynamic>)
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Future<dynamic> Function(Future<dynamic>)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 hasInitializer v (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::v
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::v
          setters
            #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::v
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer v
          reference: <testLibrary>::@class::C::@field::v
          firstFragment: #F2
          type: int Function()
          getter: <testLibrary>::@class::C::@getter::v
          setter: <testLibrary>::@class::C::@setter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F4
          returnType: int Function()
          variable: <testLibrary>::@class::C::@field::v
      setters
        synthetic v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int Function()
          returnType: void
          variable: <testLibrary>::@class::C::@field::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/nullSafe.dart
      classes
        #F1 class X1 (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@class::X1
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::X1::@constructor::new
              typeName: X1
          methods
            #F3 == (nameOffset:74) (firstTokenOffset:61) (offset:74)
              element: <testLibrary>::@class::X1::@method::==
              formalParameters
                #F4 other (nameOffset:77) (firstTokenOffset:77) (offset:77)
                  element: <testLibrary>::@class::X1::@method::==::@formalParameter::other
        #F5 class X2 (nameOffset:102) (firstTokenOffset:96) (offset:102)
          element: <testLibrary>::@class::X2
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:102)
              element: <testLibrary>::@class::X2::@constructor::new
              typeName: X2
          methods
            #F7 == (nameOffset:145) (firstTokenOffset:132) (offset:145)
              element: <testLibrary>::@class::X2::@method::==
              formalParameters
                #F8 other (nameOffset:148) (firstTokenOffset:148) (offset:148)
                  element: <testLibrary>::@class::X2::@method::==::@formalParameter::other
        #F9 class X3 (nameOffset:173) (firstTokenOffset:167) (offset:173)
          element: <testLibrary>::@class::X3
          constructors
            #F10 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:173)
              element: <testLibrary>::@class::X3::@constructor::new
              typeName: X3
          methods
            #F11 == (nameOffset:213) (firstTokenOffset:200) (offset:213)
              element: <testLibrary>::@class::X3::@method::==
              formalParameters
                #F12 other (nameOffset:216) (firstTokenOffset:216) (offset:216)
                  element: <testLibrary>::@class::X3::@method::==::@formalParameter::other
  classes
    class X1
      reference: <testLibrary>::@class::X1
      firstFragment: #F1
      supertype: NullSafeDefault
      constructors
        synthetic new
          reference: <testLibrary>::@class::X1::@constructor::new
          firstFragment: #F2
          superConstructor: package:test/nullSafe.dart::@class::NullSafeDefault::@constructor::new
      methods
        ==
          reference: <testLibrary>::@class::X1::@method::==
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional hasImplicitType other
              firstFragment: #F4
              type: Object
          returnType: bool
    class X2
      reference: <testLibrary>::@class::X2
      firstFragment: #F5
      supertype: NullSafeObject
      constructors
        synthetic new
          reference: <testLibrary>::@class::X2::@constructor::new
          firstFragment: #F6
          superConstructor: package:test/nullSafe.dart::@class::NullSafeObject::@constructor::new
      methods
        ==
          reference: <testLibrary>::@class::X2::@method::==
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional hasImplicitType other
              firstFragment: #F8
              type: Object
          returnType: bool
    class X3
      reference: <testLibrary>::@class::X3
      firstFragment: #F9
      supertype: NullSafeInt
      constructors
        synthetic new
          reference: <testLibrary>::@class::X3::@constructor::new
          firstFragment: #F10
          superConstructor: package:test/nullSafe.dart::@class::NullSafeInt::@constructor::new
      methods
        ==
          reference: <testLibrary>::@class::X3::@method::==
          firstFragment: #F11
          formalParameters
            #E2 requiredPositional hasImplicitType other
              firstFragment: #F12
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 S (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 S
            #F3 T (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: #E1 T
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F5 c (nameOffset:47) (firstTokenOffset:47) (offset:47)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F6 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
          element: <testLibrary>::@getter::c
      setters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 S
          firstFragment: #F2
          bound: num
        #E1 T
          firstFragment: #F3
          bound: C<S, T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: C<num, C<num, dynamic>>
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: C<num, C<num, dynamic>>
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F7
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F8
          type: C<num, C<num, dynamic>>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
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
        #F4 class B (nameOffset:56) (firstTokenOffset:50) (offset:56)
          element: <testLibrary>::@class::B
          fields
            #F5 hasInitializer c3 (nameOffset:66) (firstTokenOffset:66) (offset:66)
              element: <testLibrary>::@class::B::@field::c3
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F7 synthetic c3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::B::@getter::c3
          setters
            #F8 synthetic c3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::B::@setter::c3
              formalParameters
                #F9 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
                  element: <testLibrary>::@class::B::@setter::c3::@formalParameter::value
      topLevelVariables
        #F10 c (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::c
        #F11 hasInitializer c2 (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::c2
      getters
        #F12 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::c
        #F13 synthetic c2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::c2
      setters
        #F14 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::c
          formalParameters
            #F15 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F16 synthetic c2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@setter::c2
          formalParameters
            #F17 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@setter::c2::@formalParameter::value
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: C<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      fields
        hasInitializer c3
          reference: <testLibrary>::@class::B::@field::c3
          firstFragment: #F5
          type: C<C<Object?>>
          getter: <testLibrary>::@class::B::@getter::c3
          setter: <testLibrary>::@class::B::@setter::c3
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      getters
        synthetic c3
          reference: <testLibrary>::@class::B::@getter::c3
          firstFragment: #F7
          returnType: C<C<Object?>>
          variable: <testLibrary>::@class::B::@field::c3
      setters
        synthetic c3
          reference: <testLibrary>::@class::B::@setter::c3
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F9
              type: C<C<Object?>>
          returnType: void
          variable: <testLibrary>::@class::B::@field::c3
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F10
      type: C<C<dynamic>>
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasInitializer c2
      reference: <testLibrary>::@topLevelVariable::c2
      firstFragment: #F11
      type: C<C<Object?>>
      getter: <testLibrary>::@getter::c2
      setter: <testLibrary>::@setter::c2
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F12
      returnType: C<C<dynamic>>
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static c2
      reference: <testLibrary>::@getter::c2
      firstFragment: #F13
      returnType: C<C<Object?>>
      variable: <testLibrary>::@topLevelVariable::c2
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F14
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F15
          type: C<C<dynamic>>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static c2
      reference: <testLibrary>::@setter::c2
      firstFragment: #F16
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F17
          type: C<C<Object?>>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
            #F3 U (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: #E1 U
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F5 c (nameOffset:47) (firstTokenOffset:47) (offset:47)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F6 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
          element: <testLibrary>::@getter::c
      setters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: C<T, U>
        #E1 U
          firstFragment: #F3
          bound: num
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: C<C<dynamic, num>, num>
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: C<C<dynamic, num>, num>
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F7
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F8
          type: C<C<dynamic, num>, num>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/b.dart
      classes
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:31) (firstTokenOffset:29) (offset:31)
              element: <testLibrary>::@class::C::@method::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E0 T
      topLevelVariables
        #F3 f (nameOffset:33) (firstTokenOffset:33) (offset:33)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F4 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
          element: <testLibrary>::@getter::f
      setters
        #F5 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
          element: <testLibrary>::@setter::f
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@setter::f::@formalParameter::value
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: num
      aliasedType: dynamic Function(T)
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F3
      type: dynamic Function(num)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            num
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F4
      returnType: dynamic Function(num)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            num
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F5
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F6
          type: dynamic Function(num)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                num
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::B
          typeParameters
            #F5 T (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: #E1 T
            #F6 U (nameOffset:48) (firstTokenOffset:48) (offset:48)
              element: #E2 U
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      topLevelVariables
        #F8 b (nameOffset:69) (firstTokenOffset:69) (offset:69)
          element: <testLibrary>::@topLevelVariable::b
      getters
        #F9 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
          element: <testLibrary>::@getter::b
      setters
        #F10 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
          element: <testLibrary>::@setter::b
          formalParameters
            #F11 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@setter::b::@formalParameter::value
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
    notSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
          bound: int Function()
        #E2 U
          firstFragment: #F6
          bound: A<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
  topLevelVariables
    b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F8
      type: B<int Function(), A<int Function()>>
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
  getters
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F9
      returnType: B<int Function(), A<int Function()>>
      variable: <testLibrary>::@topLevelVariable::b
  setters
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F10
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F11
          type: B<int Function(), A<int Function()>>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E0 T
      topLevelVariables
        #F3 f (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F4 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::f
      setters
        #F5 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::f
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::f::@formalParameter::value
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: num
      aliasedType: S Function<S>(T)
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F3
      type: S Function<S>(num)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            num
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F4
      returnType: S Function<S>(num)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            num
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F5
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F6
          type: S Function<S>(num)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                num
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 R (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 R
          fields
            #F3 hasInitializer values (nameOffset:31) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@class::A::@field::values
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::A::@getter::values
        #F6 class B (nameOffset:55) (firstTokenOffset:49) (offset:55)
          element: <testLibrary>::@class::B
          typeParameters
            #F7 T (nameOffset:57) (firstTokenOffset:57) (offset:57)
              element: #E1 T
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 R
          firstFragment: #F2
          bound: B<num>
      fields
        final hasInitializer values
          reference: <testLibrary>::@class::A::@field::values
          firstFragment: #F3
          type: List<B<num>>
          getter: <testLibrary>::@class::A::@getter::values
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        synthetic values
          reference: <testLibrary>::@class::A::@getter::values
          firstFragment: #F5
          returnType: List<B<num>>
          variable: <testLibrary>::@class::A::@field::values
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F7
          bound: num
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
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
      topLevelVariables
        #F4 c (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F5 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::c
      setters
        #F6 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@setter::c
          formalParameters
            #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: num
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F4
      type: C<num>
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F5
      returnType: C<num>
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F7
          type: C<num>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as ppp (nameOffset:23) (firstTokenOffset:<null>) (offset:23)
      prefixes
        <testLibraryFragment>::@prefix2::ppp
          fragments: @23
      classes
        #F1 class C (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::C
          fields
            #F2 v (nameOffset:50) (firstTokenOffset:50) (offset:50)
              element: <testLibrary>::@class::C::@field::v
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::C::@getter::v
          setters
            #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::C::@setter::v
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        v
          reference: <testLibrary>::@class::C::@field::v
          firstFragment: #F2
          type: List<dynamic>
          getter: <testLibrary>::@class::C::@getter::v
          setter: <testLibrary>::@class::C::@setter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F4
          returnType: List<dynamic>
          variable: <testLibrary>::@class::C::@field::v
      setters
        synthetic v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: List<dynamic>
          returnType: void
          variable: <testLibrary>::@class::C::@field::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
        package:test/b.dart
      functions
        #F1 foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
          element: <testLibrary>::@function::foo
          formalParameters
            #F2 p (nameOffset:39) (firstTokenOffset:39) (offset:39)
              element: <testLibrary>::@function::foo::@formalParameter::p
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
      firstFragment: #F1
      formalParameters
        #E0 optionalPositional hasImplicitType p
          firstFragment: #F2
          type: dynamic
          constantInitializer
            fragment: #F2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/c.dart
      functions
        #F1 foo (nameOffset:17) (firstTokenOffset:17) (offset:17)
          element: <testLibrary>::@function::foo
          formalParameters
            #F2 p (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@function::foo::@formalParameter::p
              initializer: expression_0
                SimpleIdentifier
                  token: V @26
                  element: package:test/a.dart::@function::V
                  staticType: dynamic Function()
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 optionalPositional hasImplicitType p
          firstFragment: #F2
          type: dynamic
          constantInitializer
            fragment: #F2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 V (nameOffset:27) (firstTokenOffset:27) (offset:27)
          element: <testLibrary>::@topLevelVariable::V
      getters
        #F2 synthetic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@getter::V
      setters
        #F3 synthetic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@setter::V
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@setter::V::@formalParameter::value
      functions
        #F5 foo (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::foo
          formalParameters
            #F6 p (nameOffset:5) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@function::foo::@formalParameter::p
              initializer: expression_0
                SimpleIdentifier
                  token: V @9
                  element: <testLibrary>::@getter::V
                  staticType: dynamic
        #F7 V (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@function::V
  topLevelVariables
    V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    synthetic static V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::V
  setters
    synthetic static V
      reference: <testLibrary>::@setter::V
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::V
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F5
      formalParameters
        #E1 optionalPositional hasImplicitType p
          firstFragment: #F6
          type: dynamic
          constantInitializer
            fragment: #F6
            expression: expression_0
      returnType: dynamic
    V
      reference: <testLibrary>::@function::V
      firstFragment: #F7
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/c.dart
      topLevelVariables
        #F1 hasInitializer v (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/d.dart
      topLevelVariables
        #F1 hasInitializer v (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/c.dart
      topLevelVariables
        #F1 hasInitializer v (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
            #F5 g (nameOffset:23) (firstTokenOffset:18) (offset:23)
              element: <testLibrary>::@class::C::@method::g
              typeParameters
                #F6 V (nameOffset:25) (firstTokenOffset:25) (offset:25)
                  element: #E2 V
                #F7 W (nameOffset:28) (firstTokenOffset:28) (offset:28)
                  element: #E3 W
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
      methods
        g
          reference: <testLibrary>::@class::C::@method::g
          firstFragment: #F5
          typeParameters
            #E2 V
              firstFragment: #F6
            #E3 W
              firstFragment: #F7
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
            #F5 g (nameOffset:23) (firstTokenOffset:18) (offset:23)
              element: <testLibrary>::@class::C::@method::g
              typeParameters
                #F6 V (nameOffset:25) (firstTokenOffset:25) (offset:25)
                  element: #E2 V
                #F7 W (nameOffset:28) (firstTokenOffset:28) (offset:28)
                  element: #E3 W
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
      methods
        g
          reference: <testLibrary>::@class::C::@method::g
          firstFragment: #F5
          typeParameters
            #E2 V
              firstFragment: #F6
            #E3 W
              firstFragment: #F7
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
            #F3 U (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 U
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
            #F3 U (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 U
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
      functions
        #F3 f (nameOffset:52) (firstTokenOffset:47) (offset:52)
          element: <testLibrary>::@function::f
  topLevelVariables
    final hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int Function<T>(T)
      getter: <testLibrary>::@getter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int Function<T>(T)
      variable: <testLibrary>::@topLevelVariable::v
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
            #F3 U (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 U
          formalParameters
            #F4 b (nameOffset:18) (firstTokenOffset:13) (offset:18)
              element: <testLibrary>::@function::f::@formalParameter::b
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      formalParameters
        #E2 requiredPositional b
          firstFragment: #F4
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
          fields
            #F4 hasInitializer v (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@class::C::@field::v
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F6 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@getter::v
          setters
            #F7 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@setter::v
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::value
      functions
        #F9 f (nameOffset:74) (firstTokenOffset:69) (offset:74)
          element: <testLibrary>::@function::f
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      fields
        hasInitializer v
          reference: <testLibrary>::@class::C::@field::v
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          type: int Function(T, U)
          getter: <testLibrary>::@class::C::@getter::v
          setter: <testLibrary>::@class::C::@setter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        synthetic v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: int Function(T, U)
          variable: <testLibrary>::@class::C::@field::v
      setters
        synthetic v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F8
              type: int Function(T, U)
          returnType: void
          variable: <testLibrary>::@class::C::@field::v
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F9
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
            #F3 U (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 U
          formalParameters
            #F4 b (nameOffset:18) (firstTokenOffset:13) (offset:18)
              element: <testLibrary>::@function::f::@formalParameter::b
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      formalParameters
        #E2 requiredPositional b
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
      functions
        #F3 f (nameOffset:40) (firstTokenOffset:35) (offset:40)
          element: <testLibrary>::@function::f
  topLevelVariables
    final hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int Function()
      getter: <testLibrary>::@getter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int Function()
      variable: <testLibrary>::@topLevelVariable::v
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
      functions
        #F3 f (nameOffset:70) (firstTokenOffset:65) (offset:70)
          element: <testLibrary>::@function::f
  topLevelVariables
    final hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int Function(int, String)
      getter: <testLibrary>::@getter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int Function(int, String)
      variable: <testLibrary>::@topLevelVariable::v
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      returnType: bool
''');
  }

  test_type_arguments_explicit_dynamic_dynamic() async {
    var library = await buildLibrary('Map<dynamic, dynamic> m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 m (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::m
      getters
        #F2 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::m
      setters
        #F3 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::m
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::m::@formalParameter::value
  topLevelVariables
    m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: #F1
      type: Map<dynamic, dynamic>
      getter: <testLibrary>::@getter::m
      setter: <testLibrary>::@setter::m
  getters
    synthetic static m
      reference: <testLibrary>::@getter::m
      firstFragment: #F2
      returnType: Map<dynamic, dynamic>
      variable: <testLibrary>::@topLevelVariable::m
  setters
    synthetic static m
      reference: <testLibrary>::@setter::m
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Map<dynamic, dynamic>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::m
''');
  }

  test_type_arguments_explicit_dynamic_int() async {
    var library = await buildLibrary('Map<dynamic, int> m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 m (nameOffset:18) (firstTokenOffset:18) (offset:18)
          element: <testLibrary>::@topLevelVariable::m
      getters
        #F2 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@getter::m
      setters
        #F3 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@setter::m
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@setter::m::@formalParameter::value
  topLevelVariables
    m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: #F1
      type: Map<dynamic, int>
      getter: <testLibrary>::@getter::m
      setter: <testLibrary>::@setter::m
  getters
    synthetic static m
      reference: <testLibrary>::@getter::m
      firstFragment: #F2
      returnType: Map<dynamic, int>
      variable: <testLibrary>::@topLevelVariable::m
  setters
    synthetic static m
      reference: <testLibrary>::@setter::m
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Map<dynamic, int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::m
''');
  }

  test_type_arguments_explicit_String_dynamic() async {
    var library = await buildLibrary('Map<String, dynamic> m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 m (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::m
      getters
        #F2 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::m
      setters
        #F3 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::m
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::m::@formalParameter::value
  topLevelVariables
    m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: #F1
      type: Map<String, dynamic>
      getter: <testLibrary>::@getter::m
      setter: <testLibrary>::@setter::m
  getters
    synthetic static m
      reference: <testLibrary>::@getter::m
      firstFragment: #F2
      returnType: Map<String, dynamic>
      variable: <testLibrary>::@topLevelVariable::m
  setters
    synthetic static m
      reference: <testLibrary>::@setter::m
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Map<String, dynamic>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::m
''');
  }

  test_type_arguments_explicit_String_int() async {
    var library = await buildLibrary('Map<String, int> m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 m (nameOffset:17) (firstTokenOffset:17) (offset:17)
          element: <testLibrary>::@topLevelVariable::m
      getters
        #F2 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@getter::m
      setters
        #F3 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@setter::m
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@setter::m::@formalParameter::value
  topLevelVariables
    m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: #F1
      type: Map<String, int>
      getter: <testLibrary>::@getter::m
      setter: <testLibrary>::@setter::m
  getters
    synthetic static m
      reference: <testLibrary>::@getter::m
      firstFragment: #F2
      returnType: Map<String, int>
      variable: <testLibrary>::@topLevelVariable::m
  setters
    synthetic static m
      reference: <testLibrary>::@setter::m
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Map<String, int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::m
''');
  }

  test_type_arguments_implicit() async {
    var library = await buildLibrary('Map m;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 m (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::m
      getters
        #F2 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::m
      setters
        #F3 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::m
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::m::@formalParameter::value
  topLevelVariables
    m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: #F1
      type: Map<dynamic, dynamic>
      getter: <testLibrary>::@getter::m
      setter: <testLibrary>::@setter::m
  getters
    synthetic static m
      reference: <testLibrary>::@getter::m
      firstFragment: #F2
      returnType: Map<dynamic, dynamic>
      variable: <testLibrary>::@topLevelVariable::m
  setters
    synthetic static m
      reference: <testLibrary>::@setter::m
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Map<dynamic, dynamic>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::m
''');
  }

  test_type_dynamic() async {
    var library = await buildLibrary('dynamic d;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 d (nameOffset:8) (firstTokenOffset:8) (offset:8)
          element: <testLibrary>::@topLevelVariable::d
      getters
        #F2 synthetic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@getter::d
      setters
        #F3 synthetic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@setter::d
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@setter::d::@formalParameter::value
  topLevelVariables
    d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::d
      setter: <testLibrary>::@setter::d
  getters
    synthetic static d
      reference: <testLibrary>::@getter::d
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::d
  setters
    synthetic static d
      reference: <testLibrary>::@setter::d
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::d
''');
  }

  test_type_unresolved() async {
    var library = await buildLibrary('C c;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 c (nameOffset:2) (firstTokenOffset:2) (offset:2)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F2 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:2)
          element: <testLibrary>::@getter::c
      setters
        #F3 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:2)
          element: <testLibrary>::@setter::c
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:2)
              element: <testLibrary>::@setter::c::@formalParameter::value
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: InvalidType
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: InvalidType
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_unresolved_prefixed() async {
    var library = await buildLibrary('import "dart:core" as core; core.C c;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:core as core (nameOffset:22) (firstTokenOffset:<null>) (offset:22)
      prefixes
        <testLibraryFragment>::@prefix2::core
          fragments: @22
      topLevelVariables
        #F1 c (nameOffset:35) (firstTokenOffset:35) (offset:35)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F2 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
          element: <testLibrary>::@getter::c
      setters
        #F3 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
          element: <testLibrary>::@setter::c
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@setter::c::@formalParameter::value
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: InvalidType
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: InvalidType
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
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
