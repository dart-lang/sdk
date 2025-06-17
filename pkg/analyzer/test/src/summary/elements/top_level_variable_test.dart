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
    defineReflectiveTests(TopLevelVariableElementTest_keepLinking);
    defineReflectiveTests(TopLevelVariableElementTest_fromBytes);
    // TODO(scheglov): implement augmentation
    // defineReflectiveTests(TopLevelVariableElementTest_augmentation_keepLinking);
    // defineReflectiveTests(TopLevelVariableElementTest_augmentation_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class TopLevelVariableElementTest extends ElementsBaseTest {
  test_getter_async() async {
    var library = await buildLibrary(r'''
Future<int> get foo async => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @16
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: Future<int>
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: Future<int>
''');
  }

  test_getter_asyncStar() async {
    var library = await buildLibrary(r'''
import 'dart:async';
Stream<int> get foo async* {}
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
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @37
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: Stream<int>
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: Stream<int>
''');
  }

  test_getter_documented() async {
    var library = await buildLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
get x => null;''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @64
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
          documentationComment: /**\n * Docs\n */
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: dynamic
      getter: <testLibraryFragment>::@getter::x#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
      documentationComment: /**\n * Docs\n */
      returnType: dynamic
''');
  }

  test_getter_external() async {
    var library = await buildLibrary('external int get x;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @17
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
  getters
    static external get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
''');
  }

  test_getter_inferred_type_nonStatic_implicit_return() async {
    var library = await buildLibrary(
      'class C extends D { get f => null; } abstract class D { int get f; }',
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
              element: <testLibrary>::@class::C::@field::f
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            get f @24
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
        class D @52
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          fields
            synthetic f
              reference: <testLibraryFragment>::@class::D::@field::f
              element: <testLibrary>::@class::D::@field::f
              getter2: <testLibraryFragment>::@class::D::@getter::f
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            get f @64
              reference: <testLibraryFragment>::@class::D::@getter::f
              element: <testLibraryFragment>::@class::D::@getter::f#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      fields
        synthetic f
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibrary>::@class::D::@constructor::new
      getters
        get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
          returnType: int
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      fields
        synthetic f
          firstFragment: <testLibraryFragment>::@class::D::@field::f
          type: int
          getter: <testLibraryFragment>::@class::D::@getter::f#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      getters
        abstract get f
          firstFragment: <testLibraryFragment>::@class::D::@getter::f
          returnType: int
''');
  }

  test_getter_syncStar() async {
    var library = await buildLibrary(r'''
Iterator<int> get foo sync* {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @18
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: Iterator<int>
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: Iterator<int>
''');
  }

  test_getters() async {
    var library = await buildLibrary('int get x => null; get y => null;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
        synthetic y (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::y
          element: <testLibrary>::@topLevelVariable::y
          getter2: <testLibraryFragment>::@getter::y
      getters
        get x @8
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
        get y @23
          reference: <testLibraryFragment>::@getter::y
          element: <testLibraryFragment>::@getter::y#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
    synthetic y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      type: dynamic
      getter: <testLibraryFragment>::@getter::y#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
    static get y
      firstFragment: <testLibraryFragment>::@getter::y
      returnType: dynamic
''');
  }

  test_implicitTopLevelVariable_getterFirst() async {
    var library = await buildLibrary(
      'int get x => 0; void set x(int value) {}',
    );
    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @8
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x @25
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            value @31
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
  setters
    static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional value
          type: int
      returnType: void
''');
  }

  test_implicitTopLevelVariable_setterFirst() async {
    var library = await buildLibrary(
      'void set x(int value) {} int get x => 0;',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @33
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x @9
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            value @15
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
  setters
    static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional value
          type: int
      returnType: void
''');
  }

  test_setter_documented() async {
    var library = await buildLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
void set x(value) {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          setter2: <testLibraryFragment>::@setter::x
      setters
        set x @69
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          documentationComment: /**\n * Docs\n */
          formalParameters
            value @71
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: dynamic
      setter: <testLibraryFragment>::@setter::x#element
  setters
    static set x
      firstFragment: <testLibraryFragment>::@setter::x
      documentationComment: /**\n * Docs\n */
      formalParameters
        requiredPositional hasImplicitType value
          type: dynamic
      returnType: void
''');
  }

  test_setter_external() async {
    var library = await buildLibrary('external void set x(int value);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          setter2: <testLibraryFragment>::@setter::x
      setters
        set x @18
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            value @24
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      setter: <testLibraryFragment>::@setter::x#element
  setters
    static external set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional value
          type: int
      returnType: void
''');
  }

  test_setter_inferred_type_top_level_implicit_return() async {
    var library = await buildLibrary('set f(int value) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic f (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          setter2: <testLibraryFragment>::@setter::f
      setters
        set f @4
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            value @10
              element: <testLibraryFragment>::@setter::f::@parameter::value#element
  topLevelVariables
    synthetic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: int
      setter: <testLibraryFragment>::@setter::f#element
  setters
    static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional value
          type: int
      returnType: void
''');
  }

  test_setters() async {
    var library = await buildLibrary(
      'void set x(int value) {} set y(value) {}',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          setter2: <testLibraryFragment>::@setter::x
        synthetic y (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::y
          element: <testLibrary>::@topLevelVariable::y
          setter2: <testLibraryFragment>::@setter::y
      setters
        set x @9
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            value @15
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
        set y @29
          reference: <testLibraryFragment>::@setter::y
          element: <testLibraryFragment>::@setter::y#element
          formalParameters
            value @31
              element: <testLibraryFragment>::@setter::y::@parameter::value#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      setter: <testLibraryFragment>::@setter::x#element
    synthetic y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      type: dynamic
      setter: <testLibraryFragment>::@setter::y#element
  setters
    static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional value
          type: int
      returnType: void
    static set y
      firstFragment: <testLibraryFragment>::@setter::y
      formalParameters
        requiredPositional hasImplicitType value
          type: dynamic
      returnType: void
''');
  }

  test_top_level_variable_external() async {
    var library = await buildLibrary('''
external int i;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        i @13
          reference: <testLibraryFragment>::@topLevelVariable::i
          element: <testLibrary>::@topLevelVariable::i
          getter2: <testLibraryFragment>::@getter::i
          setter2: <testLibraryFragment>::@setter::i
      getters
        synthetic get i
          reference: <testLibraryFragment>::@getter::i
          element: <testLibraryFragment>::@getter::i#element
      setters
        synthetic set i
          reference: <testLibraryFragment>::@setter::i
          element: <testLibraryFragment>::@setter::i#element
          formalParameters
            _i
              element: <testLibraryFragment>::@setter::i::@parameter::_i#element
  topLevelVariables
    i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      type: int
      getter: <testLibraryFragment>::@getter::i#element
      setter: <testLibraryFragment>::@setter::i#element
  getters
    synthetic static get i
      firstFragment: <testLibraryFragment>::@getter::i
      returnType: int
  setters
    synthetic static set i
      firstFragment: <testLibraryFragment>::@setter::i
      formalParameters
        requiredPositional _i
          type: int
      returnType: void
''');
  }

  test_unit_implicitVariable_getterFirst() async {
    var library = await buildLibrary('''
int get x => 0;
void set x(int value) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @8
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x @25
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            value @31
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
  setters
    static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional value
          type: int
      returnType: void
''');
  }

  test_unit_implicitVariable_setterFirst() async {
    var library = await buildLibrary('''
void set x(int value) {}
int get x => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @33
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x @9
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            value @15
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
  setters
    static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional value
          type: int
      returnType: void
''');
  }

  test_unit_variable_duplicate_getter() async {
    var library = await buildLibrary('''
int foo = 0;
int get foo => 0;
''');
    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo::@def::0
          element: <testLibrary>::@topLevelVariable::foo::@def::0
          getter2: <testLibraryFragment>::@getter::foo::@def::0
          setter2: <testLibraryFragment>::@setter::foo
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo::@def::1
          element: <testLibrary>::@topLevelVariable::foo::@def::1
          getter2: <testLibraryFragment>::@getter::foo::@def::1
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo::@def::0
          element: <testLibraryFragment>::@getter::foo::@def::0#element
        get foo @21
          reference: <testLibraryFragment>::@getter::foo::@def::1
          element: <testLibraryFragment>::@getter::foo::@def::1#element
      setters
        synthetic set foo
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _foo
              element: <testLibraryFragment>::@setter::foo::@parameter::_foo#element
  topLevelVariables
    hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::0
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo::@def::0
      type: int
      getter: <testLibraryFragment>::@getter::foo::@def::0#element
      setter: <testLibraryFragment>::@setter::foo#element
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::1
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo::@def::1
      type: int
      getter: <testLibraryFragment>::@getter::foo::@def::1#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo::@def::0
      returnType: int
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo::@def::1
      returnType: int
  setters
    synthetic static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional _foo
          type: int
      returnType: void
''');
  }

  test_unit_variable_duplicate_setter() async {
    var library = await buildLibrary('''
int foo = 0;
set foo(int _) {}
''');
    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo::@def::0
          element: <testLibrary>::@topLevelVariable::foo::@def::0
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo::@def::0
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo::@def::1
          element: <testLibrary>::@topLevelVariable::foo::@def::1
          setter2: <testLibraryFragment>::@setter::foo::@def::1
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      setters
        synthetic set foo
          reference: <testLibraryFragment>::@setter::foo::@def::0
          element: <testLibraryFragment>::@setter::foo::@def::0#element
          formalParameters
            _foo
              element: <testLibraryFragment>::@setter::foo::@def::0::@parameter::_foo#element
        set foo @17
          reference: <testLibraryFragment>::@setter::foo::@def::1
          element: <testLibraryFragment>::@setter::foo::@def::1#element
          formalParameters
            _ @25
              element: <testLibraryFragment>::@setter::foo::@def::1::@parameter::_#element
  topLevelVariables
    hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::0
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo::@def::0
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
      setter: <testLibraryFragment>::@setter::foo::@def::0#element
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::1
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo::@def::1
      type: int
      setter: <testLibraryFragment>::@setter::foo::@def::1#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
  setters
    synthetic static set foo
      firstFragment: <testLibraryFragment>::@setter::foo::@def::0
      formalParameters
        requiredPositional _foo
          type: int
      returnType: void
    static set foo
      firstFragment: <testLibraryFragment>::@setter::foo::@def::1
      formalParameters
        requiredPositional _
          type: int
      returnType: void
''');
  }

  test_unit_variable_final_withSetter() async {
    var library = await buildLibrary(r'''
final int foo = 0;
set foo(int newValue) {}
''');
    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer foo @10
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      setters
        set foo @23
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            newValue @31
              element: <testLibraryFragment>::@setter::foo::@parameter::newValue#element
  topLevelVariables
    final hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
      setter: <testLibraryFragment>::@setter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
  setters
    static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional newValue
          type: int
      returnType: void
''');
  }

  test_variable() async {
    var library = await buildLibrary('int x = 0;');
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

  test_variable_const() async {
    var library = await buildLibrary('const int i = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer i @10
          reference: <testLibraryFragment>::@topLevelVariable::i
          element: <testLibrary>::@topLevelVariable::i
          initializer: expression_0
            IntegerLiteral
              literal: 0 @14
              staticType: int
          getter2: <testLibraryFragment>::@getter::i
      getters
        synthetic get i
          reference: <testLibraryFragment>::@getter::i
          element: <testLibraryFragment>::@getter::i#element
  topLevelVariables
    const hasInitializer i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::i
        expression: expression_0
      getter: <testLibraryFragment>::@getter::i#element
  getters
    synthetic static get i
      firstFragment: <testLibraryFragment>::@getter::i
      returnType: int
''');
  }

  test_variable_const_late() async {
    var library = await buildLibrary('late const int i = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer i @15
          reference: <testLibraryFragment>::@topLevelVariable::i
          element: <testLibrary>::@topLevelVariable::i
          initializer: expression_0
            IntegerLiteral
              literal: 0 @19
              staticType: int
          getter2: <testLibraryFragment>::@getter::i
      getters
        synthetic get i
          reference: <testLibraryFragment>::@getter::i
          element: <testLibraryFragment>::@getter::i#element
  topLevelVariables
    late const hasInitializer i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::i
        expression: expression_0
      getter: <testLibraryFragment>::@getter::i#element
  getters
    synthetic static get i
      firstFragment: <testLibraryFragment>::@getter::i
      returnType: int
''');
  }

  test_variable_documented() async {
    var library = await buildLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
var x;''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        x @64
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          documentationComment: /**\n * Docs\n */
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
      documentationComment: /**\n * Docs\n */
      type: dynamic
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: dynamic
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: dynamic
      returnType: void
''');
  }

  test_variable_final() async {
    var library = await buildLibrary('final int x = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @10
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    final hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
''');
  }

  test_variable_functionTyped_nested_invalid_functionTypedFormal() async {
    var library = await buildLibrary(r'''
final int Function(int, {void fn()})? foo;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        foo @38
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    final foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int Function(int, {void Function() fn})?
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int Function(int, {void Function() fn})?
''');
  }

  test_variable_getterInLib_setterInPart() async {
    newFile('$testPackageLibPath/a.dart', '''
part of my.lib;
void set x(int _) {}
''');
    var library = await buildLibrary('''
library my.lib;
part 'a.dart';
int get x => 42;''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: my.lib
  fragments
    <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      parts
        part_0
          uri: package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x::@def::0
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @39
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x::@def::1
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::x
      setters
        set x @25
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::x
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::x#element
          formalParameters
            _ @31
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::x::@parameter::_#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x::@def::0
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x::@def::1
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
      type: int
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::x#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
  setters
    static set x
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::x
      formalParameters
        requiredPositional _
          type: int
      returnType: void
''');
  }

  test_variable_getterInPart_setterInLib() async {
    newFile('$testPackageLibPath/a.dart', '''
part of my.lib;
int get x => 42;
''');
    var library = await buildLibrary('''
library my.lib;
part 'a.dart';
void set x(int _) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: my.lib
  fragments
    <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      parts
        part_0
          uri: package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x::@def::0
          setter2: <testLibraryFragment>::@setter::x
      setters
        set x @40
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _ @46
              element: <testLibraryFragment>::@setter::x::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x::@def::1
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::x
      getters
        get x @24
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::x
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::x#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x::@def::0
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      setter: <testLibraryFragment>::@setter::x#element
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x::@def::1
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
      type: int
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::x#element
  getters
    static get x
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::x
      returnType: int
  setters
    static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _
          type: int
      returnType: void
''');
  }

  test_variable_getterInPart_setterInPart() async {
    newFile('$testPackageLibPath/a.dart', 'part of my.lib; int get x => 42;');
    newFile(
      '$testPackageLibPath/b.dart',
      'part of my.lib; void set x(int _) {}',
    );
    var library = await buildLibrary(
      'library my.lib; part "a.dart"; part "b.dart";',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: my.lib
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
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x::@def::0
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::x
      getters
        get x @24
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::x
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::x#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x::@def::1
          setter2: <testLibrary>::@fragment::package:test/b.dart::@setter::x
      setters
        set x @25
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::x
          element: <testLibrary>::@fragment::package:test/b.dart::@setter::x#element
          formalParameters
            _ @31
              element: <testLibrary>::@fragment::package:test/b.dart::@setter::x::@parameter::_#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x::@def::0
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
      type: int
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::x#element
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x::@def::1
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
      type: int
      setter: <testLibrary>::@fragment::package:test/b.dart::@setter::x#element
  getters
    static get x
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::x
      returnType: int
  setters
    static set x
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@setter::x
      formalParameters
        requiredPositional _
          type: int
      returnType: void
''');
  }

  test_variable_implicit() async {
    var library = await buildLibrary('int get x => 0;');

    // We intentionally don't check the text, because we want to test
    // requesting individual elements, not all accessors/variables at once.
    var getter = library.getters.single;
    var variable = getter.variable3 as TopLevelVariableElementImpl;
    expect(variable, isNotNull);
    expect(variable.isFinal, isFalse);
    expect(variable.getter2, same(getter));
    _assertTypeStr(variable.type, 'int');
    expect(variable, same(library.topLevelVariables.single));
  }

  test_variable_implicit_type() async {
    var library = await buildLibrary('var x;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        x @4
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
      type: dynamic
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: dynamic
  setters
    synthetic static set x
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: dynamic
      returnType: void
''');
  }

  test_variable_initializer() async {
    var library = await buildLibrary('int v = 0;');
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

  test_variable_initializer_final() async {
    var library = await buildLibrary('final int v = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer v @10
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    final hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int
''');
  }

  test_variable_initializer_final_untyped() async {
    var library = await buildLibrary('final v = 0;');
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
  topLevelVariables
    final hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: int
''');
  }

  test_variable_initializer_recordType() async {
    var library = await buildLibrary('''
const x = (1, true);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @6
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            RecordLiteral
              leftParenthesis: ( @10
              fields
                IntegerLiteral
                  literal: 1 @11
                  staticType: int
                BooleanLiteral
                  literal: true @14
                  staticType: bool
              rightParenthesis: ) @18
              staticType: (int, bool)
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: (int, bool)
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::x
        expression: expression_0
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: (int, bool)
''');
  }

  test_variable_initializer_staticMethod_ofExtension() async {
    var library = await buildLibrary('''
class A {}
extension E on A {
  static int f() => 0;
}
var x = E.f();
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
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      extensions
        extension E @21
          reference: <testLibraryFragment>::@extension::E
          element: <testLibrary>::@extension::E
          methods
            f @43
              reference: <testLibraryFragment>::@extension::E::@method::f
              element: <testLibrary>::@extension::E::@method::f
      topLevelVariables
        hasInitializer x @59
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
          reference: <testLibrary>::@extension::E::@method::f
          firstFragment: <testLibraryFragment>::@extension::E::@method::f
          returnType: int
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

  test_variable_initializer_untyped() async {
    var library = await buildLibrary('var v = 0;');
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

  test_variable_late() async {
    var library = await buildLibrary('late int x = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @9
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
    late hasInitializer x
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

  test_variable_late_final() async {
    var library = await buildLibrary('late final int x;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        x @15
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
    late final x
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

  test_variable_late_final_initialized() async {
    var library = await buildLibrary('late final int x = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer x @15
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    late final hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: int
''');
  }

  test_variable_missingName() async {
    var library = await buildLibrary(r'''
Object? a,;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        a @8
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
          setter2: <testLibraryFragment>::@setter::a
        <null-name> (offset=10)
          reference: <testLibraryFragment>::@topLevelVariable::0
          element: <testLibrary>::@topLevelVariable::0
          getter2: <testLibraryFragment>::@getter::0
          setter2: <testLibraryFragment>::@setter::0
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
        synthetic get <null-name>
          reference: <testLibraryFragment>::@getter::0
          element: <testLibraryFragment>::@getter::0#element
      setters
        synthetic set a
          reference: <testLibraryFragment>::@setter::a
          element: <testLibraryFragment>::@setter::a#element
          formalParameters
            _a
              element: <testLibraryFragment>::@setter::a::@parameter::_a#element
        synthetic set <null-name>
          reference: <testLibraryFragment>::@setter::0
          element: <testLibraryFragment>::@setter::0#element
          formalParameters
            <null-name>
              element: <testLibraryFragment>::@setter::0::@parameter::#element
  topLevelVariables
    a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: Object?
      getter: <testLibraryFragment>::@getter::a#element
      setter: <testLibraryFragment>::@setter::a#element
    <null-name>
      reference: <testLibrary>::@topLevelVariable::0
      firstFragment: <testLibraryFragment>::@topLevelVariable::0
      type: Object?
      getter: <testLibraryFragment>::@getter::0#element
      setter: <testLibraryFragment>::@setter::0#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: Object?
    synthetic static get <null-name>
      firstFragment: <testLibraryFragment>::@getter::0
      returnType: Object?
  setters
    synthetic static set a
      firstFragment: <testLibraryFragment>::@setter::a
      formalParameters
        requiredPositional _a
          type: Object?
      returnType: void
    synthetic static set <null-name>
      firstFragment: <testLibraryFragment>::@setter::0
      formalParameters
        requiredPositional <null-name>
          type: Object?
      returnType: void
''');
  }

  test_variable_propagatedType_const_noDep() async {
    var library = await buildLibrary('const i = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer i @6
          reference: <testLibraryFragment>::@topLevelVariable::i
          element: <testLibrary>::@topLevelVariable::i
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          getter2: <testLibraryFragment>::@getter::i
      getters
        synthetic get i
          reference: <testLibraryFragment>::@getter::i
          element: <testLibraryFragment>::@getter::i#element
  topLevelVariables
    const hasInitializer i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::i
        expression: expression_0
      getter: <testLibraryFragment>::@getter::i#element
  getters
    synthetic static get i
      firstFragment: <testLibraryFragment>::@getter::i
      returnType: int
''');
  }

  test_variable_propagatedType_final_dep_inLib() async {
    newFile('$testPackageLibPath/a.dart', 'final a = 1;');
    var library = await buildLibrary('import "a.dart"; final b = a / 2;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        hasInitializer b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: double
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: double
''');
  }

  test_variable_propagatedType_final_dep_inPart() async {
    newFile('$testPackageLibPath/a.dart', 'part of lib; final a = 1;');
    var library = await buildLibrary(
      'library lib; part "a.dart"; final b = a / 2;',
    );
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
      topLevelVariables
        hasInitializer b @34
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibrary>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
      getters
        synthetic get b
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        hasInitializer a @19
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::a
      getters
        synthetic get a
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::a
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::a#element
  topLevelVariables
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: double
      getter: <testLibraryFragment>::@getter::b#element
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::a
      type: int
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::a#element
  getters
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
      returnType: double
    synthetic static get a
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::a
      returnType: int
''');
  }

  test_variable_propagatedType_final_noDep() async {
    var library = await buildLibrary('final i = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer i @6
          reference: <testLibraryFragment>::@topLevelVariable::i
          element: <testLibrary>::@topLevelVariable::i
          getter2: <testLibraryFragment>::@getter::i
      getters
        synthetic get i
          reference: <testLibraryFragment>::@getter::i
          element: <testLibraryFragment>::@getter::i#element
  topLevelVariables
    final hasInitializer i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      type: int
      getter: <testLibraryFragment>::@getter::i#element
  getters
    synthetic static get i
      firstFragment: <testLibraryFragment>::@getter::i
      returnType: int
''');
  }

  test_variable_propagatedType_implicit_dep() async {
    // The propagated type is defined in a library that is not imported.
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    newFile('$testPackageLibPath/b.dart', 'import "a.dart"; C f() => null;');
    var library = await buildLibrary('import "b.dart"; final x = f();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/b.dart
      topLevelVariables
        hasInitializer x @23
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        synthetic get x
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    final hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: C
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
      returnType: C
''');
  }

  test_variable_setterInPart_getterInPart() async {
    newFile(
      '$testPackageLibPath/a.dart',
      'part of my.lib; void set x(int _) {}',
    );
    newFile('$testPackageLibPath/b.dart', 'part of my.lib; int get x => 42;');
    var library = await buildLibrary(
      'library my.lib; part "a.dart"; part "b.dart";',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: my.lib
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
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x::@def::0
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::x
      setters
        set x @25
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::x
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::x#element
          formalParameters
            _ @31
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::x::@parameter::_#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic x (offset=-1)
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
          element: <testLibrary>::@topLevelVariable::x::@def::1
          getter2: <testLibrary>::@fragment::package:test/b.dart::@getter::x
      getters
        get x @24
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::x
          element: <testLibrary>::@fragment::package:test/b.dart::@getter::x#element
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x::@def::0
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
      type: int
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::x#element
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x::@def::1
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
      type: int
      getter: <testLibrary>::@fragment::package:test/b.dart::@getter::x#element
  getters
    static get x
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@getter::x
      returnType: int
  setters
    static set x
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::x
      formalParameters
        requiredPositional _
          type: int
      returnType: void
''');
  }

  test_variable_type_inferred() async {
    var library = await buildLibrary('var v = 0;');
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

  test_variable_type_inferred_Never() async {
    var library = await buildLibrary(r'''
var a = throw 42;
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
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      setters
        synthetic set a
          reference: <testLibraryFragment>::@setter::a
          element: <testLibraryFragment>::@setter::a#element
          formalParameters
            _a
              element: <testLibraryFragment>::@setter::a::@parameter::_a#element
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: Never
      getter: <testLibraryFragment>::@getter::a#element
      setter: <testLibraryFragment>::@setter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: Never
  setters
    synthetic static set a
      firstFragment: <testLibraryFragment>::@setter::a
      formalParameters
        requiredPositional _a
          type: Never
      returnType: void
''');
  }

  test_variable_type_inferred_noInitializer() async {
    var library = await buildLibrary(r'''
var a;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
          setter2: <testLibraryFragment>::@setter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      setters
        synthetic set a
          reference: <testLibraryFragment>::@setter::a
          element: <testLibraryFragment>::@setter::a#element
          formalParameters
            _a
              element: <testLibraryFragment>::@setter::a::@parameter::_a#element
  topLevelVariables
    a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
      setter: <testLibraryFragment>::@setter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: dynamic
  setters
    synthetic static set a
      firstFragment: <testLibraryFragment>::@setter::a
      formalParameters
        requiredPositional _a
          type: dynamic
      returnType: void
''');
  }

  test_variableInitializer_contextType_after_astRewrite() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A();
}
const A<int> a = A();
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
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        hasInitializer a @41
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: A @45
                  element2: <testLibrary>::@class::A
                  type: A<int>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::A::@constructor::new
                  substitution: {T: int}
              argumentList: ArgumentList
                leftParenthesis: ( @46
                rightParenthesis: ) @47
              staticType: A<int>
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: A<int>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: A<int>
''');
  }

  test_variables() async {
    var library = await buildLibrary('int i; int j;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        i @4
          reference: <testLibraryFragment>::@topLevelVariable::i
          element: <testLibrary>::@topLevelVariable::i
          getter2: <testLibraryFragment>::@getter::i
          setter2: <testLibraryFragment>::@setter::i
        j @11
          reference: <testLibraryFragment>::@topLevelVariable::j
          element: <testLibrary>::@topLevelVariable::j
          getter2: <testLibraryFragment>::@getter::j
          setter2: <testLibraryFragment>::@setter::j
      getters
        synthetic get i
          reference: <testLibraryFragment>::@getter::i
          element: <testLibraryFragment>::@getter::i#element
        synthetic get j
          reference: <testLibraryFragment>::@getter::j
          element: <testLibraryFragment>::@getter::j#element
      setters
        synthetic set i
          reference: <testLibraryFragment>::@setter::i
          element: <testLibraryFragment>::@setter::i#element
          formalParameters
            _i
              element: <testLibraryFragment>::@setter::i::@parameter::_i#element
        synthetic set j
          reference: <testLibraryFragment>::@setter::j
          element: <testLibraryFragment>::@setter::j#element
          formalParameters
            _j
              element: <testLibraryFragment>::@setter::j::@parameter::_j#element
  topLevelVariables
    i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      type: int
      getter: <testLibraryFragment>::@getter::i#element
      setter: <testLibraryFragment>::@setter::i#element
    j
      reference: <testLibrary>::@topLevelVariable::j
      firstFragment: <testLibraryFragment>::@topLevelVariable::j
      type: int
      getter: <testLibraryFragment>::@getter::j#element
      setter: <testLibraryFragment>::@setter::j#element
  getters
    synthetic static get i
      firstFragment: <testLibraryFragment>::@getter::i
      returnType: int
    synthetic static get j
      firstFragment: <testLibraryFragment>::@getter::j
      returnType: int
  setters
    synthetic static set i
      firstFragment: <testLibraryFragment>::@setter::i
      formalParameters
        requiredPositional _i
          type: int
      returnType: void
    synthetic static set j
      firstFragment: <testLibraryFragment>::@setter::j
      formalParameters
        requiredPositional _j
          type: int
      returnType: void
''');
  }

  // TODO(scheglov): This is duplicate.
  void _assertTypeStr(DartType type, String expected) {
    var typeStr = type.getDisplayString();
    expect(typeStr, expected);
  }
}

abstract class TopLevelVariableElementTest_augmentation
    extends ElementsBaseTest {
  test_variable_augments_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment int A = 0;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
class A {}
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
    checkElementText(library, r'''
library
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
        class A @21
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        augment static A @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          augmentationTargetAny: <testLibraryFragment>::@class::A
  exportedReferences
    declared <testLibraryFragment>::@class::A
  exportNamespace
    A: <testLibraryFragment>::@class::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @21
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment hasInitializer A @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::A
          element: <testLibrary>::@topLevelVariable::A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    hasInitializer A
      reference: <testLibrary>::@topLevelVariable::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::A
      type: int
  exportedReferences
    declared <testLibraryFragment>::@class::A
  exportNamespace
    A: <testLibraryFragment>::@class::A
''');
  }

  test_variable_augments_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment int foo = 0;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
void foo() {}
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
    checkElementText(library, r'''
library
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
      functions
        foo @20
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        augment static foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          augmentationTargetAny: <testLibraryFragment>::@function::foo
  exportedReferences
    declared <testLibraryFragment>::@function::foo
  exportNamespace
    foo: <testLibraryFragment>::@function::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      functions
        foo @20
          reference: <testLibraryFragment>::@function::foo
          element: <testLibrary>::@function::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment hasInitializer foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          element: <testLibrary>::@topLevelVariable::foo
  topLevelVariables
    hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
      type: int
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
      returnType: void
  exportedReferences
    declared <testLibraryFragment>::@function::foo
  exportNamespace
    foo: <testLibraryFragment>::@function::foo
''');
  }

  test_variable_augments_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment int foo = 0;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
int get foo => 0;
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
    checkElementText(library, r'''
library
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
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          id: variable_0
          getter: getter_0
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
      accessors
        static get foo @23
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        augment static foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_1
          augmentationTarget: <testLibraryFragment>::@topLevelVariable::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @23
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment hasInitializer foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: <testLibraryFragment>::@topLevelVariable::foo
  topLevelVariables
    synthetic hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
''');
  }

  test_variable_augments_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment int foo = 0;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
set foo(int _) {}
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
    checkElementText(library, r'''
library
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
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          id: variable_0
          setter: setter_0
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
      accessors
        static set foo= @19
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _ @27
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        augment static foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_1
          augmentationTarget: <testLibraryFragment>::@topLevelVariable::foo
  exportedReferences
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo=: <testLibraryFragment>::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          setter2: <testLibraryFragment>::@setter::foo
      setters
        set foo @19
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _ @27
              element: <testLibraryFragment>::@setter::foo::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment hasInitializer foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: <testLibraryFragment>::@topLevelVariable::foo
  topLevelVariables
    synthetic hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      setter: <testLibraryFragment>::@setter::foo#element
  setters
    static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional _
          type: int
  exportedReferences
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo=: <testLibraryFragment>::@setter::foo
''');
  }

  test_variable_augments_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment int foo = 1;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
int foo = 0;
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
    checkElementText(library, r'''
library
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
        static foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
        synthetic static set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        augment static foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_1
          augmentationTarget: <testLibraryFragment>::@topLevelVariable::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
    foo=: <testLibraryFragment>::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        hasInitializer foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      setters
        synthetic set foo
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _foo
              element: <testLibraryFragment>::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment hasInitializer foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: <testLibraryFragment>::@topLevelVariable::foo
  topLevelVariables
    hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
      setter: <testLibraryFragment>::@setter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    synthetic static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional _foo
          type: int
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
    foo=: <testLibraryFragment>::@setter::foo
''');
  }

  test_variable_augments_variable_augmented_const_typed() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment const int foo = augmented + 1;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
const int foo = 0;
''');

    checkElementText(library, r'''
library
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
        static const foo @25
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @31
              staticType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        augment static const foo @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            BinaryExpression
              leftOperand: AugmentedExpression
                augmentedKeyword: augmented @45
                element: <testLibraryFragment>::@topLevelVariable::foo
                fragment: <testLibraryFragment>::@topLevelVariable::foo
                staticType: int
              operator: + @55
              rightOperand: IntegerLiteral
                literal: 1 @57
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              element: dart:core::<fragment>::@class::num::@method::+#element
              staticInvokeType: num Function(num)
              staticType: int
          augmentationTarget: <testLibraryFragment>::@topLevelVariable::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        hasInitializer foo @25
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @31
              staticType: int
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment hasInitializer foo @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_1
            BinaryExpression
              leftOperand: AugmentedExpression
                augmentedKeyword: augmented @45
                element: <testLibraryFragment>::@topLevelVariable::foo
                fragment: <testLibraryFragment>::@topLevelVariable::foo
                staticType: int
              operator: + @55
              rightOperand: IntegerLiteral
                literal: 1 @57
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              element: dart:core::<fragment>::@class::num::@method::+#element
              staticInvokeType: num Function(num)
              staticType: int
          previousFragment: <testLibraryFragment>::@topLevelVariable::foo
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      constantInitializer
        fragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
        expression: expression_1
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
''');
  }
}

@reflectiveTest
class TopLevelVariableElementTest_augmentation_fromBytes
    extends TopLevelVariableElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class TopLevelVariableElementTest_augmentation_keepLinking
    extends TopLevelVariableElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => true;
}

@reflectiveTest
class TopLevelVariableElementTest_fromBytes
    extends TopLevelVariableElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class TopLevelVariableElementTest_keepLinking
    extends TopLevelVariableElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
