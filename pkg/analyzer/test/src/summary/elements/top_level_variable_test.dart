// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
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
    defineReflectiveTests(TopLevelVariableElementTest_augmentation_keepLinking);
    defineReflectiveTests(TopLevelVariableElementTest_augmentation_fromBytes);
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: Future<int>
      accessors
        static get foo @16 async
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: Future<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @16
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    synthetic foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: Future<int>
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
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
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: Stream<int>
      accessors
        static get foo @37 async*
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: Stream<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @37
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    synthetic foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: Stream<int>
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: dynamic
      accessors
        static get x @64
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          documentationComment: /**\n * Docs\n */
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @64
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
          documentationComment: /**\n * Docs\n */
  topLevelVariables
    synthetic x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: dynamic
      getter: <testLibraryFragment>::@getter::x#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
      documentationComment: /**\n * Docs\n */
''');
  }

  test_getter_external() async {
    var library = await buildLibrary('external int get x;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static external get x @17
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @17
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    synthetic x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
  getters
    static external get x
      firstFragment: <testLibraryFragment>::@getter::x
''');
  }

  test_getter_inferred_type_nonStatic_implicit_return() async {
    var library = await buildLibrary(
        'class C extends D { get f => null; } abstract class D { int get f; }');
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
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          accessors
            get f @24
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
        abstract class D @52
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          fields
            synthetic f @-1
              reference: <testLibraryFragment>::@class::D::@field::f
              enclosingElement3: <testLibraryFragment>::@class::D
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
          accessors
            abstract get f @64
              reference: <testLibraryFragment>::@class::D::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::D
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            f @-1
              reference: <testLibraryFragment>::@class::C::@field::f
              element: <testLibraryFragment>::@class::C::@field::f#element
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          getters
            get f @24
              reference: <testLibraryFragment>::@class::C::@getter::f
              element: <testLibraryFragment>::@class::C::@getter::f#element
        class D @52
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D#element
          fields
            f @-1
              reference: <testLibraryFragment>::@class::D::@field::f
              element: <testLibraryFragment>::@class::D::@field::f#element
              getter2: <testLibraryFragment>::@class::D::@getter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
          getters
            get f @64
              reference: <testLibraryFragment>::@class::D::@getter::f
              element: <testLibraryFragment>::@class::D::@getter::f#element
  classes
    class C
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
          superConstructor: <testLibraryFragment>::@class::D::@constructor::new#element
      getters
        get f
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
    abstract class D
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
''');
  }

  test_getter_syncStar() async {
    var library = await buildLibrary(r'''
Iterator<int> get foo sync* {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: Iterator<int>
      accessors
        static get foo @18 sync*
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: Iterator<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @18
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    synthetic foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: Iterator<int>
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
''');
  }

  test_getters() async {
    var library = await buildLibrary('int get x => null; get y => null;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
        synthetic static y @-1
          reference: <testLibraryFragment>::@topLevelVariable::y
          enclosingElement3: <testLibraryFragment>
          type: dynamic
      accessors
        static get x @8
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
        static get y @23
          reference: <testLibraryFragment>::@getter::y
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
        synthetic y @-1
          reference: <testLibraryFragment>::@topLevelVariable::y
          element: <testLibraryFragment>::@topLevelVariable::y#element
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
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
    synthetic y
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      type: dynamic
      getter: <testLibraryFragment>::@getter::y#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
    static get y
      firstFragment: <testLibraryFragment>::@getter::y
''');
  }

  test_implicitTopLevelVariable_getterFirst() async {
    var library =
        await buildLibrary('int get x => 0; void set x(int value) {}');
    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
          id: variable_0
          getter: getter_0
          setter: setter_0
      accessors
        static get x @8
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
        static set x= @25
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional value @31
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @8
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x= @25
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            value @31
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
  topLevelVariables
    synthetic x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional value
          type: int
''');
  }

  test_implicitTopLevelVariable_setterFirst() async {
    var library =
        await buildLibrary('void set x(int value) {} int get x => 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static set x= @9
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional value @15
              type: int
          returnType: void
        static get x @33
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @33
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x= @9
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            value @15
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
  topLevelVariables
    synthetic x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional value
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: dynamic
      accessors
        static set x= @69
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          documentationComment: /**\n * Docs\n */
          parameters
            requiredPositional value @71
              type: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          setter2: <testLibraryFragment>::@setter::x
      setters
        set x= @69
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          documentationComment: /**\n * Docs\n */
          formalParameters
            value @71
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
  topLevelVariables
    synthetic x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: dynamic
      setter: <testLibraryFragment>::@setter::x#element
  setters
    static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      documentationComment: /**\n * Docs\n */
      formalParameters
        requiredPositional value
          type: dynamic
''');
  }

  test_setter_external() async {
    var library = await buildLibrary('external void set x(int value);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static external set x= @18
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional value @24
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          setter2: <testLibraryFragment>::@setter::x
      setters
        set x= @18
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            value @24
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
  topLevelVariables
    synthetic x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      setter: <testLibraryFragment>::@setter::x#element
  setters
    static external set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional value
          type: int
''');
  }

  test_setter_inferred_type_top_level_implicit_return() async {
    var library = await buildLibrary('set f(int value) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static f @-1
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static set f= @4
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional value @10
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic f @-1
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibraryFragment>::@topLevelVariable::f#element
          setter2: <testLibraryFragment>::@setter::f
      setters
        set f= @4
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            value @10
              element: <testLibraryFragment>::@setter::f::@parameter::value#element
  topLevelVariables
    synthetic f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: int
      setter: <testLibraryFragment>::@setter::f#element
  setters
    static set f=
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional value
          type: int
''');
  }

  test_setters() async {
    var library =
        await buildLibrary('void set x(int value) {} set y(value) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
        synthetic static y @-1
          reference: <testLibraryFragment>::@topLevelVariable::y
          enclosingElement3: <testLibraryFragment>
          type: dynamic
      accessors
        static set x= @9
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional value @15
              type: int
          returnType: void
        static set y= @29
          reference: <testLibraryFragment>::@setter::y
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional value @31
              type: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          setter2: <testLibraryFragment>::@setter::x
        synthetic y @-1
          reference: <testLibraryFragment>::@topLevelVariable::y
          element: <testLibraryFragment>::@topLevelVariable::y#element
          setter2: <testLibraryFragment>::@setter::y
      setters
        set x= @9
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            value @15
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
        set y= @29
          reference: <testLibraryFragment>::@setter::y
          element: <testLibraryFragment>::@setter::y#element
          formalParameters
            value @31
              element: <testLibraryFragment>::@setter::y::@parameter::value#element
  topLevelVariables
    synthetic x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      setter: <testLibraryFragment>::@setter::x#element
    synthetic y
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      type: dynamic
      setter: <testLibraryFragment>::@setter::y#element
  setters
    static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional value
          type: int
    static set y=
      firstFragment: <testLibraryFragment>::@setter::y
      formalParameters
        requiredPositional value
          type: dynamic
''');
  }

  test_top_level_variable_external() async {
    var library = await buildLibrary('''
external int i;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static i @13
          reference: <testLibraryFragment>::@topLevelVariable::i
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        synthetic static get i @-1
          reference: <testLibraryFragment>::@getter::i
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set i= @-1
          reference: <testLibraryFragment>::@setter::i
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _i @-1
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        i @13
          reference: <testLibraryFragment>::@topLevelVariable::i
          element: <testLibraryFragment>::@topLevelVariable::i#element
          getter2: <testLibraryFragment>::@getter::i
          setter2: <testLibraryFragment>::@setter::i
      getters
        get i @-1
          reference: <testLibraryFragment>::@getter::i
          element: <testLibraryFragment>::@getter::i#element
      setters
        set i= @-1
          reference: <testLibraryFragment>::@setter::i
          element: <testLibraryFragment>::@setter::i#element
          formalParameters
            _i @-1
              element: <testLibraryFragment>::@setter::i::@parameter::_i#element
  topLevelVariables
    i
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      type: int
      getter: <testLibraryFragment>::@getter::i#element
      setter: <testLibraryFragment>::@setter::i#element
  getters
    synthetic static get i
      firstFragment: <testLibraryFragment>::@getter::i
  setters
    synthetic static set i=
      firstFragment: <testLibraryFragment>::@setter::i
      formalParameters
        requiredPositional _i
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static get x @8
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
        static set x= @25
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional value @31
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @8
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x= @25
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            value @31
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
  topLevelVariables
    synthetic x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional value
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static set x= @9
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional value @15
              type: int
          returnType: void
        static get x @33
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @33
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x= @9
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            value @15
              element: <testLibraryFragment>::@setter::x::@parameter::value#element
  topLevelVariables
    synthetic x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional value
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo::@def::0
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo::@def::1
          enclosingElement3: <testLibraryFragment>
          type: int
          id: variable_1
          getter: getter_1
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo::@def::0
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
        static get foo @21
          reference: <testLibraryFragment>::@getter::foo::@def::1
          enclosingElement3: <testLibraryFragment>
          returnType: int
          id: getter_1
          variable: variable_1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo::@def::0
          element: <testLibraryFragment>::@topLevelVariable::foo::@def::0#element
          getter2: <testLibraryFragment>::@getter::foo::@def::0
          setter2: <testLibraryFragment>::@setter::foo
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo::@def::1
          element: <testLibraryFragment>::@topLevelVariable::foo::@def::1#element
          getter2: <testLibraryFragment>::@getter::foo::@def::1
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo::@def::0
          element: <testLibraryFragment>::@getter::foo::@def::0#element
        get foo @21
          reference: <testLibraryFragment>::@getter::foo::@def::1
          element: <testLibraryFragment>::@getter::foo::@def::1#element
      setters
        set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _foo @-1
              element: <testLibraryFragment>::@setter::foo::@parameter::_foo#element
  topLevelVariables
    foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo::@def::0
      type: int
      getter: <testLibraryFragment>::@getter::foo::@def::0#element
      setter: <testLibraryFragment>::@setter::foo#element
    synthetic foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo::@def::1
      type: int
      getter: <testLibraryFragment>::@getter::foo::@def::1#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo::@def::0
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo::@def::1
  setters
    synthetic static set foo=
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional _foo
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo::@def::0
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo::@def::1
          enclosingElement3: <testLibraryFragment>
          type: int
          id: variable_1
          setter: setter_1
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
        synthetic static set foo= @-1
          reference: <testLibraryFragment>::@setter::foo::@def::0
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
        static set foo= @17
          reference: <testLibraryFragment>::@setter::foo::@def::1
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _ @25
              type: int
          returnType: void
          id: setter_1
          variable: variable_1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo::@def::0
          element: <testLibraryFragment>::@topLevelVariable::foo::@def::0#element
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo::@def::0
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo::@def::1
          element: <testLibraryFragment>::@topLevelVariable::foo::@def::1#element
          setter2: <testLibraryFragment>::@setter::foo::@def::1
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      setters
        set foo= @-1
          reference: <testLibraryFragment>::@setter::foo::@def::0
          element: <testLibraryFragment>::@setter::foo::@def::0#element
          formalParameters
            _foo @-1
              element: <testLibraryFragment>::@setter::foo::@def::0::@parameter::_foo#element
        set foo= @17
          reference: <testLibraryFragment>::@setter::foo::@def::1
          element: <testLibraryFragment>::@setter::foo::@def::1#element
          formalParameters
            _ @25
              element: <testLibraryFragment>::@setter::foo::@def::1::@parameter::_#element
  topLevelVariables
    foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo::@def::0
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
      setter: <testLibraryFragment>::@setter::foo::@def::0#element
    synthetic foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo::@def::1
      type: int
      setter: <testLibraryFragment>::@setter::foo::@def::1#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    synthetic static set foo=
      firstFragment: <testLibraryFragment>::@setter::foo::@def::0
      formalParameters
        requiredPositional _foo
          type: int
    static set foo=
      firstFragment: <testLibraryFragment>::@setter::foo::@def::1
      formalParameters
        requiredPositional _
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static final foo @10
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
        static set foo= @23
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional newValue @31
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final foo @10
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      setters
        set foo= @23
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            newValue @31
              element: <testLibraryFragment>::@setter::foo::@parameter::newValue#element
  topLevelVariables
    final foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
      setter: <testLibraryFragment>::@setter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    static set foo=
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional newValue
          type: int
''');
  }

  test_variable() async {
    var library = await buildLibrary('int x = 0;');
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
          type: int
          shouldUseTypeForInitializerInference: true
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
      topLevelVariables
        x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x @-1
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int
''');
  }

  test_variable_const() async {
    var library = await buildLibrary('const int i = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const i @10
          reference: <testLibraryFragment>::@topLevelVariable::i
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @14
              staticType: int
      accessors
        synthetic static get i @-1
          reference: <testLibraryFragment>::@getter::i
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const i @10
          reference: <testLibraryFragment>::@topLevelVariable::i
          element: <testLibraryFragment>::@topLevelVariable::i#element
          getter2: <testLibraryFragment>::@getter::i
      getters
        get i @-1
          reference: <testLibraryFragment>::@getter::i
          element: <testLibraryFragment>::@getter::i#element
  topLevelVariables
    const i
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      type: int
      getter: <testLibraryFragment>::@getter::i#element
  getters
    synthetic static get i
      firstFragment: <testLibraryFragment>::@getter::i
''');
  }

  test_variable_const_late() async {
    var library = await buildLibrary('late const int i = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static late const i @15
          reference: <testLibraryFragment>::@topLevelVariable::i
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @19
              staticType: int
      accessors
        synthetic static get i @-1
          reference: <testLibraryFragment>::@getter::i
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const i @15
          reference: <testLibraryFragment>::@topLevelVariable::i
          element: <testLibraryFragment>::@topLevelVariable::i#element
          getter2: <testLibraryFragment>::@getter::i
      getters
        get i @-1
          reference: <testLibraryFragment>::@getter::i
          element: <testLibraryFragment>::@getter::i#element
  topLevelVariables
    late const i
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      type: int
      getter: <testLibraryFragment>::@getter::i#element
  getters
    synthetic static get i
      firstFragment: <testLibraryFragment>::@getter::i
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static x @64
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          documentationComment: /**\n * Docs\n */
          type: dynamic
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        x @64
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          documentationComment: /**\n * Docs\n */
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x @-1
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: dynamic
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: dynamic
''');
  }

  test_variable_final() async {
    var library = await buildLibrary('final int x = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static final x @10
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final x @10
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    final x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
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
  name: my.lib
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static get x @39
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: int
      accessors
        static set x= @25
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::x
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _ @31
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  name: my.lib
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @39
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        synthetic x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          element: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x#element
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::x
      setters
        set x= @25
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::x
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::x#element
          formalParameters
            _ @31
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::x::@parameter::_#element
  topLevelVariables
    synthetic x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
    synthetic x
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
      type: int
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::x#element
  getters
    static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    static set x=
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::x
      formalParameters
        requiredPositional _
          type: int
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
  name: my.lib
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static set x= @40
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _ @46
              type: int
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: int
      accessors
        static get x @24
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::x
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  name: my.lib
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          setter2: <testLibraryFragment>::@setter::x
      setters
        set x= @40
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _ @46
              element: <testLibraryFragment>::@setter::x::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        synthetic x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          element: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x#element
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::x
      getters
        get x @24
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::x
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::x#element
  topLevelVariables
    synthetic x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      setter: <testLibraryFragment>::@setter::x#element
    synthetic x
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
      type: int
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::x#element
  getters
    static get x
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::x
  setters
    static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _
          type: int
''');
  }

  test_variable_getterInPart_setterInPart() async {
    newFile('$testPackageLibPath/a.dart', 'part of my.lib; int get x => 42;');
    newFile(
        '$testPackageLibPath/b.dart', 'part of my.lib; void set x(int _) {}');
    var library =
        await buildLibrary('library my.lib; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
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
      topLevelVariables
        synthetic static x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: int
      accessors
        static get x @24
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::x
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          type: int
      accessors
        static set x= @25
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::x
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          parameters
            requiredPositional _ @31
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  name: my.lib
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      topLevelVariables
        synthetic x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          element: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x#element
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::x
      getters
        get x @24
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::x
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::x#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic x @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
          element: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x#element
          setter2: <testLibrary>::@fragment::package:test/b.dart::@setter::x
      setters
        set x= @25
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::x
          element: <testLibrary>::@fragment::package:test/b.dart::@setter::x#element
          formalParameters
            _ @31
              element: <testLibrary>::@fragment::package:test/b.dart::@setter::x::@parameter::_#element
  topLevelVariables
    synthetic x
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
      type: int
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::x#element
    synthetic x
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
      type: int
      setter: <testLibrary>::@fragment::package:test/b.dart::@setter::x#element
  getters
    static get x
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::x
  setters
    static set x=
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@setter::x
      formalParameters
        requiredPositional _
          type: int
''');
  }

  test_variable_implicit() async {
    var library = await buildLibrary('int get x => 0;');

    // We intentionally don't check the text, because we want to test
    // requesting individual elements, not all accessors/variables at once.
    var getter = _elementOfDefiningUnit(library, ['@getter', 'x'])
        as PropertyAccessorElementImpl;
    var variable = getter.variable2 as TopLevelVariableElementImpl;
    expect(variable, isNotNull);
    expect(variable.isFinal, isFalse);
    expect(variable.getter, same(getter));
    _assertTypeStr(variable.type, 'int');
    expect(
      variable,
      same(
        _elementOfDefiningUnit(library, ['@topLevelVariable', 'x']),
      ),
    );
  }

  test_variable_implicit_type() async {
    var library = await buildLibrary('var x;');
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
          type: dynamic
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: dynamic
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
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x @-1
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: dynamic
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: dynamic
''');
  }

  test_variable_initializer() async {
    var library = await buildLibrary('int v = 0;');
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
          type: int
          shouldUseTypeForInitializerInference: true
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
      topLevelVariables
        v @4
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v @-1
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  topLevelVariables
    v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: int
''');
  }

  test_variable_initializer_final() async {
    var library = await buildLibrary('final int v = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static final v @10
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final v @10
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    final v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
''');
  }

  test_variable_initializer_final_untyped() async {
    var library = await buildLibrary('final v = 0;');
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
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  topLevelVariables
    final v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
''');
  }

  test_variable_initializer_recordType() async {
    var library = await buildLibrary('''
const x = (1, true);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const x @6
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: (int, bool)
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: (int, bool)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const x @6
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    const x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: (int, bool)
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
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
            static f @43
              reference: <testLibraryFragment>::@extension::E::@method::f
              enclosingElement3: <testLibraryFragment>::@extension::E
              returnType: int
      topLevelVariables
        static x @59
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
            f @43
              reference: <testLibraryFragment>::@extension::E::@method::f
              element: <testLibraryFragment>::@extension::E::@method::f#element
      topLevelVariables
        x @59
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x @-1
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
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
  topLevelVariables
    x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int
''');
  }

  test_variable_initializer_untyped() async {
    var library = await buildLibrary('var v = 0;');
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
      topLevelVariables
        v @4
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v @-1
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  topLevelVariables
    v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: int
''');
  }

  test_variable_late() async {
    var library = await buildLibrary('late int x = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static late x @9
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
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
      topLevelVariables
        x @9
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x @-1
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    late x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int
''');
  }

  test_variable_late_final() async {
    var library = await buildLibrary('late final int x;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static late final x @15
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
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
      topLevelVariables
        final x @15
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          element: <testLibraryFragment>::@setter::x#element
          formalParameters
            _x @-1
              element: <testLibraryFragment>::@setter::x::@parameter::_x#element
  topLevelVariables
    late final x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
      setter: <testLibraryFragment>::@setter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    synthetic static set x=
      firstFragment: <testLibraryFragment>::@setter::x
      formalParameters
        requiredPositional _x
          type: int
''');
  }

  test_variable_late_final_initialized() async {
    var library = await buildLibrary('late final int x = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static late final x @15
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final x @15
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    late final x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: int
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
''');
  }

  test_variable_propagatedType_const_noDep() async {
    var library = await buildLibrary('const i = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static const i @6
          reference: <testLibraryFragment>::@topLevelVariable::i
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
      accessors
        synthetic static get i @-1
          reference: <testLibraryFragment>::@getter::i
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        const i @6
          reference: <testLibraryFragment>::@topLevelVariable::i
          element: <testLibraryFragment>::@topLevelVariable::i#element
          getter2: <testLibraryFragment>::@getter::i
      getters
        get i @-1
          reference: <testLibraryFragment>::@getter::i
          element: <testLibraryFragment>::@getter::i#element
  topLevelVariables
    const i
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      type: int
      getter: <testLibraryFragment>::@getter::i#element
  getters
    synthetic static get i
      firstFragment: <testLibraryFragment>::@getter::i
''');
  }

  test_variable_propagatedType_final_dep_inLib() async {
    newFile('$testPackageLibPath/a.dart', 'final a = 1;');
    var library = await buildLibrary('import "a.dart"; final b = a / 2;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static final b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: double
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: double
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        final b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
  topLevelVariables
    final b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: double
      getter: <testLibraryFragment>::@getter::b#element
  getters
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
''');
  }

  test_variable_propagatedType_final_dep_inPart() async {
    newFile('$testPackageLibPath/a.dart', 'part of lib; final a = 1;');
    var library =
        await buildLibrary('library lib; part "a.dart"; final b = a / 2;');
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
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        static final b @34
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement3: <testLibraryFragment>
          type: double
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement3: <testLibraryFragment>
          returnType: double
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static final a @19
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::a
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::a
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  name: lib
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        final b @34
          reference: <testLibraryFragment>::@topLevelVariable::b
          element: <testLibraryFragment>::@topLevelVariable::b#element
          getter2: <testLibraryFragment>::@getter::b
      getters
        get b @-1
          reference: <testLibraryFragment>::@getter::b
          element: <testLibraryFragment>::@getter::b#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        final a @19
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::a
          element: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::a#element
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::a
      getters
        get a @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::a
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::a#element
  topLevelVariables
    final b
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      type: double
      getter: <testLibraryFragment>::@getter::b#element
    final a
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::a
      type: int
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::a#element
  getters
    synthetic static get b
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get a
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::a
''');
  }

  test_variable_propagatedType_final_noDep() async {
    var library = await buildLibrary('final i = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static final i @6
          reference: <testLibraryFragment>::@topLevelVariable::i
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get i @-1
          reference: <testLibraryFragment>::@getter::i
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        final i @6
          reference: <testLibraryFragment>::@topLevelVariable::i
          element: <testLibraryFragment>::@topLevelVariable::i#element
          getter2: <testLibraryFragment>::@getter::i
      getters
        get i @-1
          reference: <testLibraryFragment>::@getter::i
          element: <testLibraryFragment>::@getter::i#element
  topLevelVariables
    final i
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      type: int
      getter: <testLibraryFragment>::@getter::i#element
  getters
    synthetic static get i
      firstFragment: <testLibraryFragment>::@getter::i
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
      topLevelVariables
        static final x @23
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement3: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement3: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/b.dart
      topLevelVariables
        final x @23
          reference: <testLibraryFragment>::@topLevelVariable::x
          element: <testLibraryFragment>::@topLevelVariable::x#element
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
          element: <testLibraryFragment>::@getter::x#element
  topLevelVariables
    final x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      type: C
      getter: <testLibraryFragment>::@getter::x#element
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x
''');
  }

  test_variable_setterInPart_getterInPart() async {
    newFile(
        '$testPackageLibPath/a.dart', 'part of my.lib; void set x(int _) {}');
    newFile('$testPackageLibPath/b.dart', 'part of my.lib; int get x => 42;');
    var library =
        await buildLibrary('library my.lib; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
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
      topLevelVariables
        synthetic static x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          type: int
      accessors
        static set x= @25
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::x
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _ @31
              type: int
          returnType: void
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          type: int
      accessors
        static get x @24
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::x
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  name: my.lib
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      topLevelVariables
        synthetic x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          element: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x#element
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::x
      setters
        set x= @25
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::x
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::x#element
          formalParameters
            _ @31
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::x::@parameter::_#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic x @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
          element: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x#element
          getter2: <testLibrary>::@fragment::package:test/b.dart::@getter::x
      getters
        get x @24
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::x
          element: <testLibrary>::@fragment::package:test/b.dart::@getter::x#element
  topLevelVariables
    synthetic x
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
      type: int
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::x#element
    synthetic x
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
      type: int
      getter: <testLibrary>::@fragment::package:test/b.dart::@getter::x#element
  getters
    static get x
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@getter::x
  setters
    static set x=
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::x
      formalParameters
        requiredPositional _
          type: int
''');
  }

  test_variable_type_inferred() async {
    var library = await buildLibrary('var v = 0;');
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
      topLevelVariables
        v @4
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v @-1
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  topLevelVariables
    v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: int
''');
  }

  test_variable_type_inferred_Never() async {
    var library = await buildLibrary(r'''
var a = throw 42;
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
          type: Never
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: Never
        synthetic static set a= @-1
          reference: <testLibraryFragment>::@setter::a
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _a @-1
              type: Never
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
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
          setter2: <testLibraryFragment>::@setter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      setters
        set a= @-1
          reference: <testLibraryFragment>::@setter::a
          element: <testLibraryFragment>::@setter::a#element
          formalParameters
            _a @-1
              element: <testLibraryFragment>::@setter::a::@parameter::_a#element
  topLevelVariables
    a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: Never
      getter: <testLibraryFragment>::@getter::a#element
      setter: <testLibraryFragment>::@setter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
  setters
    synthetic static set a=
      firstFragment: <testLibraryFragment>::@setter::a
      formalParameters
        requiredPositional _a
          type: Never
''');
  }

  test_variable_type_inferred_noInitializer() async {
    var library = await buildLibrary(r'''
var a;
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
          type: dynamic
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
          setter2: <testLibraryFragment>::@setter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
      setters
        set a= @-1
          reference: <testLibraryFragment>::@setter::a
          element: <testLibraryFragment>::@setter::a#element
          formalParameters
            _a @-1
              element: <testLibraryFragment>::@setter::a::@parameter::_a#element
  topLevelVariables
    a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: dynamic
      getter: <testLibraryFragment>::@getter::a#element
      setter: <testLibraryFragment>::@setter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
  setters
    synthetic static set a=
      firstFragment: <testLibraryFragment>::@setter::a
      formalParameters
        requiredPositional _a
          type: dynamic
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
      topLevelVariables
        static const a @41
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: A<int>
          shouldUseTypeForInitializerInference: true
          constantInitializer
            InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: A @45
                  element: <testLibraryFragment>::@class::A
                  element2: <testLibraryFragment>::@class::A#element
                  type: A<int>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: int}
                element: <testLibraryFragment>::@class::A::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @46
                rightParenthesis: ) @47
              staticType: A<int>
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: A<int>
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
      topLevelVariables
        const a @41
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: A<int>
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
''');
  }

  test_variables() async {
    var library = await buildLibrary('int i; int j;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static i @4
          reference: <testLibraryFragment>::@topLevelVariable::i
          enclosingElement3: <testLibraryFragment>
          type: int
        static j @11
          reference: <testLibraryFragment>::@topLevelVariable::j
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        synthetic static get i @-1
          reference: <testLibraryFragment>::@getter::i
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set i= @-1
          reference: <testLibraryFragment>::@setter::i
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _i @-1
              type: int
          returnType: void
        synthetic static get j @-1
          reference: <testLibraryFragment>::@getter::j
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set j= @-1
          reference: <testLibraryFragment>::@setter::j
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _j @-1
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        i @4
          reference: <testLibraryFragment>::@topLevelVariable::i
          element: <testLibraryFragment>::@topLevelVariable::i#element
          getter2: <testLibraryFragment>::@getter::i
          setter2: <testLibraryFragment>::@setter::i
        j @11
          reference: <testLibraryFragment>::@topLevelVariable::j
          element: <testLibraryFragment>::@topLevelVariable::j#element
          getter2: <testLibraryFragment>::@getter::j
          setter2: <testLibraryFragment>::@setter::j
      getters
        get i @-1
          reference: <testLibraryFragment>::@getter::i
          element: <testLibraryFragment>::@getter::i#element
        get j @-1
          reference: <testLibraryFragment>::@getter::j
          element: <testLibraryFragment>::@getter::j#element
      setters
        set i= @-1
          reference: <testLibraryFragment>::@setter::i
          element: <testLibraryFragment>::@setter::i#element
          formalParameters
            _i @-1
              element: <testLibraryFragment>::@setter::i::@parameter::_i#element
        set j= @-1
          reference: <testLibraryFragment>::@setter::j
          element: <testLibraryFragment>::@setter::j#element
          formalParameters
            _j @-1
              element: <testLibraryFragment>::@setter::j::@parameter::_j#element
  topLevelVariables
    i
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      type: int
      getter: <testLibraryFragment>::@getter::i#element
      setter: <testLibraryFragment>::@setter::i#element
    j
      firstFragment: <testLibraryFragment>::@topLevelVariable::j
      type: int
      getter: <testLibraryFragment>::@getter::j#element
      setter: <testLibraryFragment>::@setter::j#element
  getters
    synthetic static get i
      firstFragment: <testLibraryFragment>::@getter::i
    synthetic static get j
      firstFragment: <testLibraryFragment>::@getter::j
  setters
    synthetic static set i=
      firstFragment: <testLibraryFragment>::@setter::i
      formalParameters
        requiredPositional _i
          type: int
    synthetic static set j=
      firstFragment: <testLibraryFragment>::@setter::j
      formalParameters
        requiredPositional _j
          type: int
''');
  }

  // TODO(scheglov): This is duplicate.
  void _assertTypeStr(DartType type, String expected) {
    var typeStr = type.getDisplayString();
    expect(typeStr, expected);
  }

  // TODO(scheglov): This is duplicate.
  Element _elementOfDefiningUnit(
      LibraryElementImpl library, List<String> names) {
    var reference = library.definingCompilationUnit.reference!;
    for (var name in names) {
      reference = reference.getChild(name);
    }

    var element = reference.element;
    if (element != null) {
      return element;
    }

    var elementFactory = library.linkedData!.elementFactory;
    return elementFactory.elementOfReference(reference)!;
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
  parts
    part_0
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
          getter: getter_0
          setter: setter_0
          augmentationTargetAny: <testLibraryFragment>::@class::A
      accessors
        synthetic static get A @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_0
          variable: variable_0
        synthetic static set A= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _A @-1
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::A
    declared <testLibrary>::@fragment::package:test/a.dart::@setter::A
  exportNamespace
    A: <testLibrary>::@fragment::package:test/a.dart::@getter::A
    A=: <testLibrary>::@fragment::package:test/a.dart::@setter::A
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
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment A @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::A#element
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::A
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::A
      getters
        get A @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::A
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::A#element
      setters
        set A= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::A
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::A#element
          formalParameters
            _A @-1
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::A::@parameter::_A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::A
      type: int
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::A#element
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::A#element
  getters
    synthetic static get A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::A
  setters
    synthetic static set A=
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::A
      formalParameters
        requiredPositional _A
          type: int
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::A
    declared <testLibrary>::@fragment::package:test/a.dart::@setter::A
  exportNamespace
    A: <testLibrary>::@fragment::package:test/a.dart::@getter::A
    A=: <testLibrary>::@fragment::package:test/a.dart::@setter::A
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
  parts
    part_0
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
          getter: getter_0
          setter: setter_0
          augmentationTargetAny: <testLibraryFragment>::@function::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_0
          variable: variable_0
        synthetic static set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    declared <testLibrary>::@fragment::package:test/a.dart::@setter::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    foo=: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
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
          element: <testLibraryFragment>::@function::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo#element
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
      getters
        get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::foo#element
      setters
        set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::foo#element
          formalParameters
            _foo @-1
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::foo::@parameter::_foo#element
  topLevelVariables
    foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
      type: int
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::foo#element
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
  setters
    synthetic static set foo=
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
      formalParameters
        requiredPositional _foo
          type: int
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      returnType: void
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    declared <testLibrary>::@fragment::package:test/a.dart::@setter::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    foo=: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
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
  parts
    part_0
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
          getter: getter_1
          setter: setter_0
          augmentationTargetAny: <testLibraryFragment>::@getter::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_1
          variable: variable_1
        synthetic static set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_0
          variable: variable_1
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    declared <testLibrary>::@fragment::package:test/a.dart::@setter::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    foo=: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @23
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo#element
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
      getters
        get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::foo#element
      setters
        set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::foo#element
          formalParameters
            _foo @-1
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::foo::@parameter::_foo#element
  topLevelVariables
    synthetic foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
    foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
      type: int
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::foo#element
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
    synthetic static get foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
  setters
    synthetic static set foo=
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
      formalParameters
        requiredPositional _foo
          type: int
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    declared <testLibrary>::@fragment::package:test/a.dart::@setter::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    foo=: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
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
  parts
    part_0
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
          getter: getter_0
          setter: setter_1
          augmentationTargetAny: <testLibraryFragment>::@setter::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_0
          variable: variable_1
        synthetic static set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_1
          variable: variable_1
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    declared <testLibrary>::@fragment::package:test/a.dart::@setter::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    foo=: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          setter2: <testLibraryFragment>::@setter::foo
      setters
        set foo= @19
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _ @27
              element: <testLibraryFragment>::@setter::foo::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo#element
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
      getters
        get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::foo#element
      setters
        set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::foo#element
          formalParameters
            _foo @-1
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::foo::@parameter::_foo#element
  topLevelVariables
    synthetic foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      setter: <testLibraryFragment>::@setter::foo#element
    foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
      type: int
      getter: <testLibrary>::@fragment::package:test/a.dart::@getter::foo#element
      setter: <testLibrary>::@fragment::package:test/a.dart::@setter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
  setters
    static set foo=
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional _
          type: int
    synthetic static set foo=
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
      formalParameters
        requiredPositional _foo
          type: int
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    declared <testLibrary>::@fragment::package:test/a.dart::@setter::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    foo=: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
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
  parts
    part_0
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
          getter: getter_1
          setter: setter_1
          augmentationTarget: <testLibraryFragment>::@topLevelVariable::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_1
          variable: variable_1
        synthetic static set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_1
          variable: variable_1
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    declared <testLibrary>::@fragment::package:test/a.dart::@setter::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    foo=: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      setters
        set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _foo @-1
              element: <testLibraryFragment>::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          previousFragment: <testLibraryFragment>::@topLevelVariable::foo
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
      getters
        get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::foo#element
      setters
        set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@setter::foo#element
          formalParameters
            _foo @-1
              element: <testLibrary>::@fragment::package:test/a.dart::@setter::foo::@parameter::_foo#element
  topLevelVariables
    foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
      setter: <testLibraryFragment>::@setter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
    synthetic static get foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
  setters
    synthetic static set foo=
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional _foo
          type: int
    synthetic static set foo=
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
      formalParameters
        requiredPositional _foo
          type: int
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    declared <testLibrary>::@fragment::package:test/a.dart::@setter::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
    foo=: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
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
  parts
    part_0
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
                element2: <testLibraryFragment>::@topLevelVariable::foo#element
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
      accessors
        synthetic static get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        const foo @25
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment const foo @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          previousFragment: <testLibraryFragment>::@topLevelVariable::foo
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
      getters
        get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
    synthetic static get foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
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
