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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: Future<int>
      accessors
        static get foo @16 async
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: Future<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @16
          reference: <testLibraryFragment>::@getter::foo
  topLevelVariables
    synthetic foo
      reference: <none>
      type: Future<int>
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    static get foo
      reference: <none>
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:async
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: Stream<int>
      accessors
        static get foo @37 async*
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: Stream<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        dart:async
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @37
          reference: <testLibraryFragment>::@getter::foo
  topLevelVariables
    synthetic foo
      reference: <none>
      type: Stream<int>
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    static get foo
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: dynamic
      accessors
        static get x @64
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          documentationComment: /**\n * Docs\n */
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @64
          reference: <testLibraryFragment>::@getter::x
          documentationComment: /**\n * Docs\n */
  topLevelVariables
    synthetic x
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
  getters
    static get x
      reference: <none>
      documentationComment: /**\n * Docs\n */
      firstFragment: <testLibraryFragment>::@getter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        static external get x @17
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @17
          reference: <testLibraryFragment>::@getter::x
  topLevelVariables
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
  getters
    static external get x
      reference: <none>
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
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          accessors
            get f @24
              reference: <testLibraryFragment>::@class::C::@getter::f
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int
        abstract class D @52
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          fields
            synthetic f @-1
              reference: <testLibraryFragment>::@class::D::@field::f
              enclosingElement: <testLibraryFragment>::@class::D
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
          accessors
            abstract get f @64
              reference: <testLibraryFragment>::@class::D::@getter::f
              enclosingElement: <testLibraryFragment>::@class::D
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            f @-1
              reference: <testLibraryFragment>::@class::C::@field::f
              getter2: <testLibraryFragment>::@class::C::@getter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              superConstructor: <testLibraryFragment>::@class::D::@constructor::new
          getters
            get f @24
              reference: <testLibraryFragment>::@class::C::@getter::f
        class D @52
          reference: <testLibraryFragment>::@class::D
          fields
            f @-1
              reference: <testLibraryFragment>::@class::D::@field::f
              getter2: <testLibraryFragment>::@class::D::@getter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
          getters
            get f @64
              reference: <testLibraryFragment>::@class::D::@getter::f
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: D
      fields
        synthetic f
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::f
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        get f
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::f
    abstract class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      fields
        synthetic f
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::D::@field::f
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
      getters
        abstract get f
          reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: Iterator<int>
      accessors
        static get foo @18 sync*
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: Iterator<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @18
          reference: <testLibraryFragment>::@getter::foo
  topLevelVariables
    synthetic foo
      reference: <none>
      type: Iterator<int>
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    static get foo
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
        synthetic static y @-1
          reference: <testLibraryFragment>::@topLevelVariable::y
          enclosingElement: <testLibraryFragment>
          type: dynamic
      accessors
        static get x @8
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
        static get y @23
          reference: <testLibraryFragment>::@getter::y
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
        synthetic y @-1
          reference: <testLibraryFragment>::@topLevelVariable::y
          getter2: <testLibraryFragment>::@getter::y
      getters
        get x @8
          reference: <testLibraryFragment>::@getter::x
        get y @23
          reference: <testLibraryFragment>::@getter::y
  topLevelVariables
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
    synthetic y
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      getter: <none>
  getters
    static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
    static get y
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
          id: variable_0
          getter: getter_0
          setter: setter_0
      accessors
        static get x @8
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
        static set x= @25
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @8
          reference: <testLibraryFragment>::@getter::x
      setters
        set x= @25
          reference: <testLibraryFragment>::@setter::x
          parameters
            value @31
  topLevelVariables
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    static set x=
      reference: <none>
      parameters
        requiredPositional value
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        static set x= @9
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional value @15
              type: int
          returnType: void
        static get x @33
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @33
          reference: <testLibraryFragment>::@getter::x
      setters
        set x= @9
          reference: <testLibraryFragment>::@setter::x
          parameters
            value @15
  topLevelVariables
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    static set x=
      reference: <none>
      parameters
        requiredPositional value
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: dynamic
      accessors
        static set x= @69
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
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
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          setter2: <testLibraryFragment>::@setter::x
      setters
        set x= @69
          reference: <testLibraryFragment>::@setter::x
          documentationComment: /**\n * Docs\n */
          parameters
            value @71
  topLevelVariables
    synthetic x
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      setter: <none>
  setters
    static set x=
      reference: <none>
      documentationComment: /**\n * Docs\n */
      parameters
        requiredPositional value
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        static external set x= @18
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional value @24
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          setter2: <testLibraryFragment>::@setter::x
      setters
        set x= @18
          reference: <testLibraryFragment>::@setter::x
          parameters
            value @24
  topLevelVariables
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      setter: <none>
  setters
    static external set x=
      reference: <none>
      parameters
        requiredPositional value
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static f @-1
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        static set f= @4
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional value @10
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        synthetic f @-1
          reference: <testLibraryFragment>::@topLevelVariable::f
          setter2: <testLibraryFragment>::@setter::f
      setters
        set f= @4
          reference: <testLibraryFragment>::@setter::f
          parameters
            value @10
  topLevelVariables
    synthetic f
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      setter: <none>
  setters
    static set f=
      reference: <none>
      parameters
        requiredPositional value
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::f
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
        synthetic static y @-1
          reference: <testLibraryFragment>::@topLevelVariable::y
          enclosingElement: <testLibraryFragment>
          type: dynamic
      accessors
        static set x= @9
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional value @15
              type: int
          returnType: void
        static set y= @29
          reference: <testLibraryFragment>::@setter::y
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional value @31
              type: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          setter2: <testLibraryFragment>::@setter::x
        synthetic y @-1
          reference: <testLibraryFragment>::@topLevelVariable::y
          setter2: <testLibraryFragment>::@setter::y
      setters
        set x= @9
          reference: <testLibraryFragment>::@setter::x
          parameters
            value @15
        set y= @29
          reference: <testLibraryFragment>::@setter::y
          parameters
            value @31
  topLevelVariables
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      setter: <none>
    synthetic y
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::y
      setter: <none>
  setters
    static set x=
      reference: <none>
      parameters
        requiredPositional value
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::x
    static set y=
      reference: <none>
      parameters
        requiredPositional value
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::y
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static i @13
          reference: <testLibraryFragment>::@topLevelVariable::i
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        synthetic static get i @-1
          reference: <testLibraryFragment>::@getter::i
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set i= @-1
          reference: <testLibraryFragment>::@setter::i
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _i @-1
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        i @13
          reference: <testLibraryFragment>::@topLevelVariable::i
          getter2: <testLibraryFragment>::@getter::i
          setter2: <testLibraryFragment>::@setter::i
      getters
        get i @-1
          reference: <testLibraryFragment>::@getter::i
      setters
        set i= @-1
          reference: <testLibraryFragment>::@setter::i
          parameters
            _i @-1
  topLevelVariables
    i
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      getter: <none>
      setter: <none>
  getters
    synthetic static get i
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::i
  setters
    synthetic static set i=
      reference: <none>
      parameters
        requiredPositional _i
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::i
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        static get x @8
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
        static set x= @25
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional value @31
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @8
          reference: <testLibraryFragment>::@getter::x
      setters
        set x= @25
          reference: <testLibraryFragment>::@setter::x
          parameters
            value @31
  topLevelVariables
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    static set x=
      reference: <none>
      parameters
        requiredPositional value
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        static set x= @9
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional value @15
              type: int
          returnType: void
        static get x @33
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @33
          reference: <testLibraryFragment>::@getter::x
      setters
        set x= @9
          reference: <testLibraryFragment>::@setter::x
          parameters
            value @15
  topLevelVariables
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
      setter: <none>
  getters
    static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    static set x=
      reference: <none>
      parameters
        requiredPositional value
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          id: variable_1
          getter: getter_1
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo::@def::0
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
        synthetic static set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
        static get foo @21
          reference: <testLibraryFragment>::@getter::foo::@def::1
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_1
          variable: variable_1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo::@def::0
          setter2: <testLibraryFragment>::@setter::foo
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo::@def::1
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo::@def::0
        get foo @21
          reference: <testLibraryFragment>::@getter::foo::@def::1
      setters
        set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          parameters
            _foo @-1
  topLevelVariables
    foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
      setter: <none>
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo::@def::0
    static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo::@def::1
  setters
    synthetic static set foo=
      reference: <none>
      parameters
        requiredPositional _foo
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          id: variable_1
          setter: setter_1
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
        synthetic static set foo= @-1
          reference: <testLibraryFragment>::@setter::foo::@def::0
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
        static set foo= @17
          reference: <testLibraryFragment>::@setter::foo::@def::1
          enclosingElement: <testLibraryFragment>
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
      topLevelVariables
        foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo::@def::0
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          setter2: <testLibraryFragment>::@setter::foo::@def::1
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
      setters
        set foo= @-1
          reference: <testLibraryFragment>::@setter::foo::@def::0
          parameters
            _foo @-1
        set foo= @17
          reference: <testLibraryFragment>::@setter::foo::@def::1
          parameters
            _ @25
  topLevelVariables
    foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
      setter: <none>
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      setter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    synthetic static set foo=
      reference: <none>
      parameters
        requiredPositional _foo
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo::@def::0
    static set foo=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo::@def::1
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static final foo @10
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
        static set foo= @23
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement: <testLibraryFragment>
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
      topLevelVariables
        final foo @10
          reference: <testLibraryFragment>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
      setters
        set foo= @23
          reference: <testLibraryFragment>::@setter::foo
          parameters
            newValue @31
  topLevelVariables
    final foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
      setter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    static set foo=
      reference: <none>
      parameters
        requiredPositional newValue
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
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
      topLevelVariables
        x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          parameters
            _x @-1
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

  test_variable_const() async {
    var library = await buildLibrary('const int i = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static const i @10
          reference: <testLibraryFragment>::@topLevelVariable::i
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @14
              staticType: int
      accessors
        synthetic static get i @-1
          reference: <testLibraryFragment>::@getter::i
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        const i @10
          reference: <testLibraryFragment>::@topLevelVariable::i
          getter2: <testLibraryFragment>::@getter::i
      getters
        get i @-1
          reference: <testLibraryFragment>::@getter::i
  topLevelVariables
    const i
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      getter: <none>
  getters
    synthetic static get i
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static late const i @15
          reference: <testLibraryFragment>::@topLevelVariable::i
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @19
              staticType: int
      accessors
        synthetic static get i @-1
          reference: <testLibraryFragment>::@getter::i
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        const i @15
          reference: <testLibraryFragment>::@topLevelVariable::i
          getter2: <testLibraryFragment>::@getter::i
      getters
        get i @-1
          reference: <testLibraryFragment>::@getter::i
  topLevelVariables
    late const i
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      getter: <none>
  getters
    synthetic static get i
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static x @64
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          documentationComment: /**\n * Docs\n */
          type: dynamic
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        x @64
          reference: <testLibraryFragment>::@topLevelVariable::x
          documentationComment: /**\n * Docs\n */
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          parameters
            _x @-1
  topLevelVariables
    x
      reference: <none>
      type: dynamic
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
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static final x @10
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        final x @10
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
  topLevelVariables
    final x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
  getters
    synthetic static get x
      reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        static get x @39
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
      accessors
        static set x= @25
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::x
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @39
          reference: <testLibraryFragment>::@getter::x
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      topLevelVariables
        synthetic x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::x
      setters
        set x= @25
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::x
          parameters
            _ @31
  topLevelVariables
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
      setter: <none>
  getters
    static get x
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::x
  setters
    static set x=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::x
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        static set x= @40
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _ @46
              type: int
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
      accessors
        static get x @24
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::x
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  name: my.lib
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic x @-1
          reference: <testLibraryFragment>::@topLevelVariable::x
          setter2: <testLibraryFragment>::@setter::x
      setters
        set x= @40
          reference: <testLibraryFragment>::@setter::x
          parameters
            _ @46
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      topLevelVariables
        synthetic x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::x
      getters
        get x @24
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::x
  topLevelVariables
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      setter: <none>
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
      getter: <none>
  getters
    static get x
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::x
  setters
    static set x=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::x
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
      topLevelVariables
        synthetic static x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
      accessors
        static get x @24
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::x
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          type: int
      accessors
        static set x= @25
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::x
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      topLevelVariables
        synthetic x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::x
      getters
        get x @24
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::x
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic x @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
          setter2: <testLibrary>::@fragment::package:test/b.dart::@setter::x
      setters
        set x= @25
          reference: <testLibrary>::@fragment::package:test/b.dart::@setter::x
          parameters
            _ @31
  topLevelVariables
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
      getter: <none>
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
      setter: <none>
  getters
    static get x
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::x
  setters
    static set x=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: dynamic
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        x @4
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          parameters
            _x @-1
  topLevelVariables
    x
      reference: <none>
      type: dynamic
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
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static v @4
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
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
      topLevelVariables
        v @4
          reference: <testLibraryFragment>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          parameters
            _v @-1
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

  test_variable_initializer_final() async {
    var library = await buildLibrary('final int v = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static final v @10
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        final v @10
          reference: <testLibraryFragment>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
  topLevelVariables
    final v
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
  getters
    synthetic static get v
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static final v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        final v @6
          reference: <testLibraryFragment>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
  topLevelVariables
    final v
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
  getters
    synthetic static get v
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const x @6
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: (int, bool)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        const x @6
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
  topLevelVariables
    const x
      reference: <none>
      type: (int, bool)
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
  getters
    synthetic static get x
      reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      extensions
        E @21
          reference: <testLibraryFragment>::@extension::E
          enclosingElement: <testLibraryFragment>
          extendedType: A
          methods
            static f @43
              reference: <testLibraryFragment>::@extension::E::@method::f
              enclosingElement: <testLibraryFragment>::@extension::E
              returnType: int
      topLevelVariables
        static x @59
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
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
      extensions
        extension E @21
          reference: <testLibraryFragment>::@extension::E
          methods
            f @43
              reference: <testLibraryFragment>::@extension::E::@method::f
      topLevelVariables
        x @59
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          parameters
            _x @-1
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  extensions
    extension E
      reference: <testLibraryFragment>::@extension::E
      firstFragment: <testLibraryFragment>::@extension::E
      methods
        static f
          reference: <none>
          firstFragment: <testLibraryFragment>::@extension::E::@method::f
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

  test_variable_initializer_untyped() async {
    var library = await buildLibrary('var v = 0;');
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
      topLevelVariables
        v @4
          reference: <testLibraryFragment>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          parameters
            _v @-1
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

  test_variable_late() async {
    var library = await buildLibrary('late int x = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static late x @9
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
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
      topLevelVariables
        x @9
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          parameters
            _x @-1
  topLevelVariables
    late x
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

  test_variable_late_final() async {
    var library = await buildLibrary('late final int x;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static late final x @15
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
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
      topLevelVariables
        final x @15
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
          setter2: <testLibraryFragment>::@setter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x
          parameters
            _x @-1
  topLevelVariables
    late final x
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

  test_variable_late_final_initialized() async {
    var library = await buildLibrary('late final int x = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static late final x @15
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        final x @15
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
  topLevelVariables
    late final x
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
  getters
    synthetic static get x
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static const i @6
          reference: <testLibraryFragment>::@topLevelVariable::i
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @10
              staticType: int
      accessors
        synthetic static get i @-1
          reference: <testLibraryFragment>::@getter::i
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        const i @6
          reference: <testLibraryFragment>::@topLevelVariable::i
          getter2: <testLibraryFragment>::@getter::i
      getters
        get i @-1
          reference: <testLibraryFragment>::@getter::i
  topLevelVariables
    const i
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      getter: <none>
  getters
    synthetic static get i
      reference: <none>
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
        static final b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: double
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: double
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      topLevelVariables
        final b @23
          reference: <testLibraryFragment>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
      getters
        get b @-1
          reference: <testLibraryFragment>::@getter::b
  topLevelVariables
    final b
      reference: <none>
      type: double
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
  getters
    synthetic static get b
      reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        static final b @34
          reference: <testLibraryFragment>::@topLevelVariable::b
          enclosingElement: <testLibraryFragment>
          type: double
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get b @-1
          reference: <testLibraryFragment>::@getter::b
          enclosingElement: <testLibraryFragment>
          returnType: double
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static final a @19
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::a
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::a
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  name: lib
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        final b @34
          reference: <testLibraryFragment>::@topLevelVariable::b
          getter2: <testLibraryFragment>::@getter::b
      getters
        get b @-1
          reference: <testLibraryFragment>::@getter::b
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      topLevelVariables
        final a @19
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::a
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::a
      getters
        get a @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::a
  topLevelVariables
    final b
      reference: <none>
      type: double
      firstFragment: <testLibraryFragment>::@topLevelVariable::b
      getter: <none>
    final a
      reference: <none>
      type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get b
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::b
    synthetic static get a
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static final i @6
          reference: <testLibraryFragment>::@topLevelVariable::i
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get i @-1
          reference: <testLibraryFragment>::@getter::i
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        final i @6
          reference: <testLibraryFragment>::@topLevelVariable::i
          getter2: <testLibraryFragment>::@getter::i
      getters
        get i @-1
          reference: <testLibraryFragment>::@getter::i
  topLevelVariables
    final i
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      getter: <none>
  getters
    synthetic static get i
      reference: <none>
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static final x @23
          reference: <testLibraryFragment>::@topLevelVariable::x
          enclosingElement: <testLibraryFragment>
          type: C
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x
          enclosingElement: <testLibraryFragment>
          returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/b.dart
      topLevelVariables
        final x @23
          reference: <testLibraryFragment>::@topLevelVariable::x
          getter2: <testLibraryFragment>::@getter::x
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x
  topLevelVariables
    final x
      reference: <none>
      type: C
      firstFragment: <testLibraryFragment>::@topLevelVariable::x
      getter: <none>
  getters
    synthetic static get x
      reference: <none>
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
      topLevelVariables
        synthetic static x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
      accessors
        static set x= @25
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::x
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _ @31
              type: int
          returnType: void
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        synthetic static x @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          type: int
      accessors
        static get x @24
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::x
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  name: my.lib
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      topLevelVariables
        synthetic x @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::x
      setters
        set x= @25
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::x
          parameters
            _ @31
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic x @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
          getter2: <testLibrary>::@fragment::package:test/b.dart::@getter::x
      getters
        get x @24
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::x
  topLevelVariables
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::x
      setter: <none>
    synthetic x
      reference: <none>
      type: int
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::x
      getter: <none>
  getters
    static get x
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@getter::x
  setters
    static set x=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::x
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static v @4
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
      topLevelVariables
        v @4
          reference: <testLibraryFragment>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          parameters
            _v @-1
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: Never
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: Never
        synthetic static set a= @-1
          reference: <testLibraryFragment>::@setter::a
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _a @-1
              type: Never
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
          setter2: <testLibraryFragment>::@setter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
      setters
        set a= @-1
          reference: <testLibraryFragment>::@setter::a
          parameters
            _a @-1
  topLevelVariables
    a
      reference: <none>
      type: Never
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
      setter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
  setters
    synthetic static set a=
      reference: <none>
      parameters
        requiredPositional _a
          reference: <none>
          type: Never
      firstFragment: <testLibraryFragment>::@setter::a
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: dynamic
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        a @4
          reference: <testLibraryFragment>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
          setter2: <testLibraryFragment>::@setter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
      setters
        set a= @-1
          reference: <testLibraryFragment>::@setter::a
          parameters
            _a @-1
  topLevelVariables
    a
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
      setter: <none>
  getters
    synthetic static get a
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::a
  setters
    synthetic static set a=
      reference: <none>
      parameters
        requiredPositional _a
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::a
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      topLevelVariables
        static const a @41
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: A<int>
          shouldUseTypeForInitializerInference: true
          constantInitializer
            InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: A @45
                  element: <testLibraryFragment>::@class::A
                  type: A<int>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: int}
              argumentList: ArgumentList
                leftParenthesis: ( @46
                rightParenthesis: ) @47
              staticType: A<int>
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: A<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          typeParameters
            T @8
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
      topLevelVariables
        const a @41
          reference: <testLibraryFragment>::@topLevelVariable::a
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const a
      reference: <none>
      type: A<int>
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static i @4
          reference: <testLibraryFragment>::@topLevelVariable::i
          enclosingElement: <testLibraryFragment>
          type: int
        static j @11
          reference: <testLibraryFragment>::@topLevelVariable::j
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        synthetic static get i @-1
          reference: <testLibraryFragment>::@getter::i
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set i= @-1
          reference: <testLibraryFragment>::@setter::i
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _i @-1
              type: int
          returnType: void
        synthetic static get j @-1
          reference: <testLibraryFragment>::@getter::j
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set j= @-1
          reference: <testLibraryFragment>::@setter::j
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _j @-1
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      topLevelVariables
        i @4
          reference: <testLibraryFragment>::@topLevelVariable::i
          getter2: <testLibraryFragment>::@getter::i
          setter2: <testLibraryFragment>::@setter::i
        j @11
          reference: <testLibraryFragment>::@topLevelVariable::j
          getter2: <testLibraryFragment>::@getter::j
          setter2: <testLibraryFragment>::@setter::j
      getters
        get i @-1
          reference: <testLibraryFragment>::@getter::i
        get j @-1
          reference: <testLibraryFragment>::@getter::j
      setters
        set i= @-1
          reference: <testLibraryFragment>::@setter::i
          parameters
            _i @-1
        set j= @-1
          reference: <testLibraryFragment>::@setter::j
          parameters
            _j @-1
  topLevelVariables
    i
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::i
      getter: <none>
      setter: <none>
    j
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::j
      getter: <none>
      setter: <none>
  getters
    synthetic static get i
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::i
    synthetic static get j
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::j
  setters
    synthetic static set i=
      reference: <none>
      parameters
        requiredPositional _i
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::i
    synthetic static set j=
      reference: <none>
      parameters
        requiredPositional _j
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::j
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @21
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        augment static A @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
          augmentationTargetAny: <testLibraryFragment>::@class::A
      accessors
        synthetic static get A @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_0
          variable: variable_0
        synthetic static set A= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @21
          reference: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment A @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::A
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::A
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::A
      getters
        get A @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::A
      setters
        set A= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::A
          parameters
            _A @-1
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    A
      reference: <none>
      type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::A
      getter: <none>
      setter: <none>
  getters
    synthetic static get A
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::A
  setters
    synthetic static set A=
      reference: <none>
      parameters
        requiredPositional _A
          reference: <none>
          type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::A
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      functions
        foo @20
          reference: <testLibraryFragment>::@function::foo
          enclosingElement: <testLibraryFragment>
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        augment static foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
          augmentationTargetAny: <testLibraryFragment>::@function::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_0
          variable: variable_0
        synthetic static set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
      getters
        get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
      setters
        set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          parameters
            _foo @-1
  topLevelVariables
    foo
      reference: <none>
      type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
      getter: <none>
      setter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
  setters
    synthetic static set foo=
      reference: <none>
      parameters
        requiredPositional _foo
          reference: <none>
          type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          id: variable_0
          getter: getter_0
      accessors
        static get foo @23
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        augment static foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_1
          getter: getter_1
          setter: setter_0
          augmentationTargetAny: <testLibraryFragment>::@getter::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_1
          variable: variable_1
        synthetic static set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @23
          reference: <testLibraryFragment>::@getter::foo
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
      getters
        get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
      setters
        set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          parameters
            _foo @-1
  topLevelVariables
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
    foo
      reference: <none>
      type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
      getter: <none>
      setter: <none>
  getters
    static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
  setters
    synthetic static set foo=
      reference: <none>
      parameters
        requiredPositional _foo
          reference: <none>
          type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          id: variable_0
          setter: setter_0
      accessors
        static set foo= @19
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _ @27
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        augment static foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_1
          getter: getter_0
          setter: setter_1
          augmentationTargetAny: <testLibraryFragment>::@setter::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_0
          variable: variable_1
        synthetic static set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          setter2: <testLibraryFragment>::@setter::foo
      setters
        set foo= @19
          reference: <testLibraryFragment>::@setter::foo
          parameters
            _ @27
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
      getters
        get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
      setters
        set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          parameters
            _foo @-1
  topLevelVariables
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      setter: <none>
    foo
      reference: <none>
      type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
      getter: <none>
      setter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
  setters
    static set foo=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo
    synthetic static set foo=
      reference: <none>
      parameters
        requiredPositional _foo
          reference: <none>
          type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        static foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
        synthetic static set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        augment static foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_1
          getter: getter_1
          setter: setter_1
          augmentationTarget: <testLibraryFragment>::@topLevelVariable::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_1
          variable: variable_1
        synthetic static set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
      setters
        set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          parameters
            _foo @-1
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          previousFragment: <testLibraryFragment>::@topLevelVariable::foo
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          setter2: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
      getters
        get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
      setters
        set foo= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
          parameters
            _foo @-1
  topLevelVariables
    foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
      setter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
  setters
    synthetic static set foo=
      reference: <none>
      parameters
        requiredPositional _foo
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo
    synthetic static set foo=
      reference: <none>
      parameters
        requiredPositional _foo
          reference: <none>
          type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setter::foo
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        static const foo @25
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
          returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        augment static const foo @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            BinaryExpression
              leftOperand: AugmentedExpression
                augmentedKeyword: augmented @45
                element: <testLibraryFragment>::@topLevelVariable::foo
                staticType: int
              operator: + @55
              rightOperand: IntegerLiteral
                literal: 1 @57
                staticType: int
              staticElement: dart:core::<fragment>::@class::num::@method::+
              staticInvokeType: num Function(num)
              staticType: int
          augmentationTarget: <testLibraryFragment>::@topLevelVariable::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        const foo @25
          reference: <testLibraryFragment>::@topLevelVariable::foo
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      topLevelVariables
        augment const foo @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariableAugmentation::foo
          previousFragment: <testLibraryFragment>::@topLevelVariable::foo
          getter2: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
      getters
        get foo @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::foo
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
    synthetic static get foo
      reference: <none>
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
