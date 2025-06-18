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
  test_fragmentOrder_g1_s2_s1() async {
    var library = await buildLibrary(r'''
int get a => 0;
set b(int _) {}
set a(int _) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic a (offset=-1)
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
        #F4 synthetic b (offset=-1)
          element: <testLibrary>::@topLevelVariable::b
          setter: #F5
      getters
        #F2 a @8
          element: <testLibrary>::@getter::a
          returnType: int
          variable: #F1
      setters
        #F5 b @20
          element: <testLibrary>::@setter::b
          formalParameters
            #F6 _ @26
              element: <testLibrary>::@setter::b::@formalParameter::_
        #F3 a @36
          element: <testLibrary>::@setter::a
          formalParameters
            #F7 _ @42
              element: <testLibrary>::@setter::a::@formalParameter::_
  topLevelVariables
    synthetic a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    synthetic b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: int
      setter: <testLibrary>::@setter::b
  getters
    static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
  setters
    static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F5
      formalParameters
        requiredPositional _
          firstFragment: #F6
          type: int
      returnType: void
    static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _
          firstFragment: #F7
          type: int
      returnType: void
''');
  }

  test_fragmentOrder_s1_g2_g1() async {
    var library = await buildLibrary(r'''
set a(int _) {}
int get b => 0;
int get a => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic a (offset=-1)
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
        #F4 synthetic b (offset=-1)
          element: <testLibrary>::@topLevelVariable::b
          getter: #F5
      getters
        #F5 b @24
          element: <testLibrary>::@getter::b
          returnType: int
          variable: #F4
        #F2 a @40
          element: <testLibrary>::@getter::a
          returnType: int
          variable: #F1
      setters
        #F3 a @4
          element: <testLibrary>::@setter::a
          formalParameters
            #F6 _ @10
              element: <testLibrary>::@setter::a::@formalParameter::_
  topLevelVariables
    synthetic a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    synthetic b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::b
  getters
    static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
    static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
  setters
    static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _
          firstFragment: #F6
          type: int
      returnType: void
''');
  }

  test_getter_async() async {
    var library = await buildLibrary(r'''
Future<int> get foo async => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic foo (offset=-1)
          element: <testLibrary>::@topLevelVariable::foo
          getter: #F2
      getters
        #F2 foo @16
          element: <testLibrary>::@getter::foo
          returnType: Future<int>
          variable: #F1
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: Future<int>
      getter: <testLibrary>::@getter::foo
  getters
    static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: Future<int>
      variable: <testLibrary>::@topLevelVariable::foo
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        #F1 synthetic foo (offset=-1)
          element: <testLibrary>::@topLevelVariable::foo
          getter: #F2
      getters
        #F2 foo @37
          element: <testLibrary>::@getter::foo
          returnType: Stream<int>
          variable: #F1
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: Stream<int>
      getter: <testLibrary>::@getter::foo
  getters
    static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: Stream<int>
      variable: <testLibrary>::@topLevelVariable::foo
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
      getters
        #F2 x @64
          element: <testLibrary>::@getter::x
          documentationComment: /**\n * Docs\n */
          returnType: dynamic
          variable: #F1
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::x
  getters
    static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      documentationComment: /**\n * Docs\n */
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_getter_external() async {
    var library = await buildLibrary('external int get x;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
      getters
        #F2 x @17
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
  getters
    static external x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          fields
            #F2 synthetic f
              element: <testLibrary>::@class::C::@field::f
              getter2: #F3
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 f @24
              element: <testLibrary>::@class::C::@getter::f
              returnType: int
              variable: #F2
        #F5 class D @52
          element: <testLibrary>::@class::D
          fields
            #F6 synthetic f
              element: <testLibrary>::@class::D::@field::f
              getter2: #F7
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F7 f @64
              element: <testLibrary>::@class::D::@getter::f
              returnType: int
              variable: #F6
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      fields
        synthetic f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::D::@constructor::new
      getters
        f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: #F5
      fields
        synthetic f
          reference: <testLibrary>::@class::D::@field::f
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::D::@getter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F8
      getters
        abstract f
          reference: <testLibrary>::@class::D::@getter::f
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@class::D::@field::f
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic foo (offset=-1)
          element: <testLibrary>::@topLevelVariable::foo
          getter: #F2
      getters
        #F2 foo @18
          element: <testLibrary>::@getter::foo
          returnType: Iterator<int>
          variable: #F1
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: Iterator<int>
      getter: <testLibrary>::@getter::foo
  getters
    static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: Iterator<int>
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_getters() async {
    var library = await buildLibrary('int get x => null; get y => null;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
        #F3 synthetic y (offset=-1)
          element: <testLibrary>::@topLevelVariable::y
          getter: #F4
      getters
        #F2 x @8
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
        #F4 y @23
          element: <testLibrary>::@getter::y
          returnType: dynamic
          variable: #F3
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
    synthetic y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::y
  getters
    static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
    static y
      reference: <testLibrary>::@getter::y
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::y
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 x @8
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
      setters
        #F3 x @25
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value @31
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        requiredPositional value
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 x @33
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
      setters
        #F3 x @9
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value @15
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        requiredPositional value
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          setter: #F2
      setters
        #F2 x @69
          element: <testLibrary>::@setter::x
          documentationComment: /**\n * Docs\n */
          formalParameters
            #F3 value @71
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: dynamic
      setter: <testLibrary>::@setter::x
  setters
    static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F2
      documentationComment: /**\n * Docs\n */
      formalParameters
        requiredPositional hasImplicitType value
          firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          setter: #F2
      setters
        #F2 x @18
          element: <testLibrary>::@setter::x
          formalParameters
            #F3 value @24
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::x
  setters
    static external x
      reference: <testLibrary>::@setter::x
      firstFragment: #F2
      formalParameters
        requiredPositional value
          firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic f (offset=-1)
          element: <testLibrary>::@topLevelVariable::f
          setter: #F2
      setters
        #F2 f @4
          element: <testLibrary>::@setter::f
          formalParameters
            #F3 value @10
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    synthetic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::f
  setters
    static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F2
      formalParameters
        requiredPositional value
          firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          setter: #F2
        #F3 synthetic y (offset=-1)
          element: <testLibrary>::@topLevelVariable::y
          setter: #F4
      setters
        #F2 x @9
          element: <testLibrary>::@setter::x
          formalParameters
            #F5 value @15
              element: <testLibrary>::@setter::x::@formalParameter::value
        #F4 y @29
          element: <testLibrary>::@setter::y
          formalParameters
            #F6 value @31
              element: <testLibrary>::@setter::y::@formalParameter::value
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::x
    synthetic y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F3
      type: dynamic
      setter: <testLibrary>::@setter::y
  setters
    static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F2
      formalParameters
        requiredPositional value
          firstFragment: #F5
          type: int
      returnType: void
    static y
      reference: <testLibrary>::@setter::y
      firstFragment: #F4
      formalParameters
        requiredPositional hasImplicitType value
          firstFragment: #F6
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 i @13
          element: <testLibrary>::@topLevelVariable::i
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic i
          element: <testLibrary>::@getter::i
          returnType: int
          variable: #F1
      setters
        #F3 synthetic i
          element: <testLibrary>::@setter::i
          formalParameters
            #F4 _i
              element: <testLibrary>::@setter::i::@formalParameter::_i
  topLevelVariables
    i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::i
      setter: <testLibrary>::@setter::i
  getters
    synthetic static i
      reference: <testLibrary>::@getter::i
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::i
  setters
    synthetic static i
      reference: <testLibrary>::@setter::i
      firstFragment: #F3
      formalParameters
        requiredPositional _i
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 x @8
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
      setters
        #F3 x @25
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value @31
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        requiredPositional value
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 x @33
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
      setters
        #F3 x @9
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value @15
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
''');
  }

  test_unit_variable_duplicate() async {
    var library = await buildLibrary('''
int foo = 0;
int foo = 1;
''');
    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer foo @4
          element: <testLibrary>::@topLevelVariable::foo::@def::0
          getter: #F2
          setter: #F3
        #F4 hasInitializer foo @17
          element: <testLibrary>::@topLevelVariable::foo::@def::1
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic foo
          element: <testLibrary>::@getter::foo::@def::0
          returnType: int
          variable: #F1
        #F5 synthetic foo
          element: <testLibrary>::@getter::foo::@def::1
          returnType: int
          variable: #F4
      setters
        #F3 synthetic foo
          element: <testLibrary>::@setter::foo::@def::0
          formalParameters
            #F7 _foo
              element: <testLibrary>::@setter::foo::@def::0::@formalParameter::_foo
        #F6 synthetic foo
          element: <testLibrary>::@setter::foo::@def::1
          formalParameters
            #F8 _foo
              element: <testLibrary>::@setter::foo::@def::1::@formalParameter::_foo
  topLevelVariables
    hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::0
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo::@def::0
      setter: <testLibrary>::@setter::foo::@def::0
    hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::1
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::foo::@def::1
      setter: <testLibrary>::@setter::foo::@def::1
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo::@def::0
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo::@def::0
    synthetic static foo
      reference: <testLibrary>::@getter::foo::@def::1
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo::@def::1
  setters
    synthetic static foo
      reference: <testLibrary>::@setter::foo::@def::0
      firstFragment: #F3
      formalParameters
        requiredPositional _foo
          firstFragment: #F7
          type: int
      returnType: void
    synthetic static foo
      reference: <testLibrary>::@setter::foo::@def::1
      firstFragment: #F6
      formalParameters
        requiredPositional _foo
          firstFragment: #F8
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer foo @4
          element: <testLibrary>::@topLevelVariable::foo::@def::0
          getter: #F2
          setter: #F3
        #F4 synthetic foo (offset=-1)
          element: <testLibrary>::@topLevelVariable::foo::@def::1
          getter: #F5
      getters
        #F2 synthetic foo
          element: <testLibrary>::@getter::foo::@def::0
          returnType: int
          variable: #F1
        #F5 foo @21
          element: <testLibrary>::@getter::foo::@def::1
          returnType: int
          variable: #F4
      setters
        #F3 synthetic foo
          element: <testLibrary>::@setter::foo
          formalParameters
            #F6 _foo
              element: <testLibrary>::@setter::foo::@formalParameter::_foo
  topLevelVariables
    hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::0
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo::@def::0
      setter: <testLibrary>::@setter::foo
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::1
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::foo::@def::1
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo::@def::0
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo::@def::0
    static foo
      reference: <testLibrary>::@getter::foo::@def::1
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo::@def::1
  setters
    synthetic static foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        requiredPositional _foo
          firstFragment: #F6
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer foo @4
          element: <testLibrary>::@topLevelVariable::foo::@def::0
          getter: #F2
          setter: #F3
        #F4 synthetic foo (offset=-1)
          element: <testLibrary>::@topLevelVariable::foo::@def::1
          setter: #F5
      getters
        #F2 synthetic foo
          element: <testLibrary>::@getter::foo
          returnType: int
          variable: #F1
      setters
        #F3 synthetic foo
          element: <testLibrary>::@setter::foo::@def::0
          formalParameters
            #F6 _foo
              element: <testLibrary>::@setter::foo::@def::0::@formalParameter::_foo
        #F5 foo @17
          element: <testLibrary>::@setter::foo::@def::1
          formalParameters
            #F7 _ @25
              element: <testLibrary>::@setter::foo::@def::1::@formalParameter::_
  topLevelVariables
    hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::0
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo::@def::0
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::1
      firstFragment: #F4
      type: int
      setter: <testLibrary>::@setter::foo::@def::1
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo::@def::0
  setters
    synthetic static foo
      reference: <testLibrary>::@setter::foo::@def::0
      firstFragment: #F3
      formalParameters
        requiredPositional _foo
          firstFragment: #F6
          type: int
      returnType: void
    static foo
      reference: <testLibrary>::@setter::foo::@def::1
      firstFragment: #F5
      formalParameters
        requiredPositional _
          firstFragment: #F7
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer foo @10
          element: <testLibrary>::@topLevelVariable::foo
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic foo
          element: <testLibrary>::@getter::foo
          returnType: int
          variable: #F1
      setters
        #F3 foo @23
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 newValue @31
              element: <testLibrary>::@setter::foo::@formalParameter::newValue
  topLevelVariables
    final hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    static foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        requiredPositional newValue
          firstFragment: #F4
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

  test_variable_const() async {
    var library = await buildLibrary('const int i = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer i @10
          element: <testLibrary>::@topLevelVariable::i
          initializer: expression_0
            IntegerLiteral
              literal: 0 @14
              staticType: int
          getter: #F2
      getters
        #F2 synthetic i
          element: <testLibrary>::@getter::i
          returnType: int
          variable: #F1
  topLevelVariables
    const hasInitializer i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::i
  getters
    synthetic static i
      reference: <testLibrary>::@getter::i
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::i
''');
  }

  test_variable_const_late() async {
    var library = await buildLibrary('late const int i = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer i @15
          element: <testLibrary>::@topLevelVariable::i
          initializer: expression_0
            IntegerLiteral
              literal: 0 @19
              staticType: int
          getter: #F2
      getters
        #F2 synthetic i
          element: <testLibrary>::@getter::i
          returnType: int
          variable: #F1
  topLevelVariables
    late const hasInitializer i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::i
  getters
    synthetic static i
      reference: <testLibrary>::@getter::i
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::i
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 x @64
          element: <testLibrary>::@topLevelVariable::x
          documentationComment: /**\n * Docs\n */
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: dynamic
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  topLevelVariables
    x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      documentationComment: /**\n * Docs\n */
      type: dynamic
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        requiredPositional _x
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer x @10
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
  topLevelVariables
    final hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 foo @38
          element: <testLibrary>::@topLevelVariable::foo
          getter: #F2
      getters
        #F2 synthetic foo
          element: <testLibrary>::@getter::foo
          returnType: int Function(int, {void Function() fn})?
          variable: #F1
  topLevelVariables
    final foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int Function(int, {void Function() fn})?
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int Function(int, {void Function() fn})?
      variable: <testLibrary>::@topLevelVariable::foo
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
    #F0 <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          unit: #F1
      topLevelVariables
        #F2 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          getter: #F3
          setter: #F4
      getters
        #F3 x @39
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F2
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      setters
        #F4 x @25
          element: <testLibrary>::@setter::x
          formalParameters
            #F5 _ @31
              element: <testLibrary>::@setter::x::@formalParameter::_
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F4
      formalParameters
        requiredPositional _
          firstFragment: #F5
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
    #F0 <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          unit: #F1
      topLevelVariables
        #F2 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          getter: #F3
          setter: #F4
      setters
        #F4 x @40
          element: <testLibrary>::@setter::x
          formalParameters
            #F5 _ @46
              element: <testLibrary>::@setter::x::@formalParameter::_
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      getters
        #F3 x @24
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F2
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F4
      formalParameters
        requiredPositional _
          firstFragment: #F5
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
      topLevelVariables
        #F3 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          getter: #F4
          setter: #F5
      getters
        #F4 x @24
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F3
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F1
      setters
        #F5 x @25
          element: <testLibrary>::@setter::x
          formalParameters
            #F6 _ @31
              element: <testLibrary>::@setter::x::@formalParameter::_
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F5
      formalParameters
        requiredPositional _
          firstFragment: #F6
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 x @4
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: dynamic
          variable: #F1
      setters
        #F3 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  topLevelVariables
    x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        requiredPositional _x
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer v @4
          element: <testLibrary>::@topLevelVariable::v
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic v
          element: <testLibrary>::@getter::v
          returnType: int
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
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        requiredPositional _v
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer v @10
          element: <testLibrary>::@topLevelVariable::v
          getter: #F2
      getters
        #F2 synthetic v
          element: <testLibrary>::@getter::v
          returnType: int
          variable: #F1
  topLevelVariables
    final hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_variable_initializer_final_untyped() async {
    var library = await buildLibrary('final v = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer v @6
          element: <testLibrary>::@topLevelVariable::v
          getter: #F2
      getters
        #F2 synthetic v
          element: <testLibrary>::@getter::v
          returnType: int
          variable: #F1
  topLevelVariables
    final hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer x @6
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
          getter: #F2
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: (int, bool)
          variable: #F1
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: (int, bool)
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: (int, bool)
      variable: <testLibrary>::@topLevelVariable::x
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      extensions
        #F3 extension E @21
          element: <testLibrary>::@extension::E
          methods
            #F4 f @43
              element: <testLibrary>::@extension::E::@method::f
      topLevelVariables
        #F5 hasInitializer x @59
          element: <testLibrary>::@topLevelVariable::x
          getter: #F6
          setter: #F7
      getters
        #F6 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F5
      setters
        #F7 synthetic x
          element: <testLibrary>::@setter::x
          formalParameters
            #F8 _x
              element: <testLibrary>::@setter::x::@formalParameter::_x
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F3
      extendedType: A
      methods
        static f
          reference: <testLibrary>::@extension::E::@method::f
          firstFragment: #F4
          returnType: int
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F5
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F7
      formalParameters
        requiredPositional _x
          firstFragment: #F8
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer v @4
          element: <testLibrary>::@topLevelVariable::v
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic v
          element: <testLibrary>::@getter::v
          returnType: int
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
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        requiredPositional _v
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer x @9
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
    late hasInitializer x
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

  test_variable_late_final() async {
    var library = await buildLibrary('late final int x;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 x @15
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
    late final x
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

  test_variable_late_final_initialized() async {
    var library = await buildLibrary('late final int x = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer x @15
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F1
  topLevelVariables
    late final hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 a @8
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
        #F4 <null-name> (offset=10)
          element: <testLibrary>::@topLevelVariable::0
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: Object?
          variable: #F1
        #F5 synthetic <null-name>
          element: <testLibrary>::@getter::1
          returnType: Object?
          variable: #F4
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F7 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
        #F6 synthetic <null-name>
          element: <testLibrary>::@setter::2
          formalParameters
            #F8 _
              element: <testLibrary>::@setter::2::@formalParameter::_
  topLevelVariables
    a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: Object?
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    <null-name>
      reference: <testLibrary>::@topLevelVariable::0
      firstFragment: #F4
      type: Object?
      getter: <testLibrary>::@getter::1
      setter: <testLibrary>::@setter::2
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: Object?
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static <null-name>
      reference: <testLibrary>::@getter::1
      firstFragment: #F5
      returnType: Object?
      variable: <testLibrary>::@topLevelVariable::0
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F7
          type: Object?
      returnType: void
    synthetic static <null-name>
      reference: <testLibrary>::@setter::2
      firstFragment: #F6
      formalParameters
        requiredPositional _
          firstFragment: #F8
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer i @6
          element: <testLibrary>::@topLevelVariable::i
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          getter: #F2
      getters
        #F2 synthetic i
          element: <testLibrary>::@getter::i
          returnType: int
          variable: #F1
  topLevelVariables
    const hasInitializer i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::i
  getters
    synthetic static i
      reference: <testLibrary>::@getter::i
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::i
''');
  }

  test_variable_propagatedType_final_dep_inLib() async {
    newFile('$testPackageLibPath/a.dart', 'final a = 1;');
    var library = await buildLibrary('import "a.dart"; final b = a / 2;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 hasInitializer b @23
          element: <testLibrary>::@topLevelVariable::b
          getter: #F2
      getters
        #F2 synthetic b
          element: <testLibrary>::@getter::b
          returnType: double
          variable: #F1
  topLevelVariables
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F1
      type: double
      getter: <testLibrary>::@getter::b
  getters
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F2
      returnType: double
      variable: <testLibrary>::@topLevelVariable::b
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
    #F0 <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          unit: #F1
      topLevelVariables
        #F2 hasInitializer b @34
          element: <testLibrary>::@topLevelVariable::b
          getter: #F3
      getters
        #F3 synthetic b
          element: <testLibrary>::@getter::b
          returnType: double
          variable: #F2
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      topLevelVariables
        #F4 hasInitializer a @19
          element: <testLibrary>::@topLevelVariable::a
          getter: #F5
      getters
        #F5 synthetic a
          element: <testLibrary>::@getter::a
          returnType: int
          variable: #F4
  topLevelVariables
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::b
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::a
  getters
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F3
      returnType: double
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_variable_propagatedType_final_noDep() async {
    var library = await buildLibrary('final i = 0;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer i @6
          element: <testLibrary>::@topLevelVariable::i
          getter: #F2
      getters
        #F2 synthetic i
          element: <testLibrary>::@getter::i
          returnType: int
          variable: #F1
  topLevelVariables
    final hasInitializer i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::i
  getters
    synthetic static i
      reference: <testLibrary>::@getter::i
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::i
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/b.dart
      topLevelVariables
        #F1 hasInitializer x @23
          element: <testLibrary>::@topLevelVariable::x
          getter: #F2
      getters
        #F2 synthetic x
          element: <testLibrary>::@getter::x
          returnType: C
          variable: #F1
  topLevelVariables
    final hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::x
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
      topLevelVariables
        #F3 synthetic x (offset=-1)
          element: <testLibrary>::@topLevelVariable::x
          getter: #F4
          setter: #F5
      setters
        #F5 x @25
          element: <testLibrary>::@setter::x
          formalParameters
            #F6 _ @31
              element: <testLibrary>::@setter::x::@formalParameter::_
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F1
      getters
        #F4 x @24
          element: <testLibrary>::@getter::x
          returnType: int
          variable: #F3
  topLevelVariables
    synthetic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F5
      formalParameters
        requiredPositional _
          firstFragment: #F6
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer v @4
          element: <testLibrary>::@topLevelVariable::v
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic v
          element: <testLibrary>::@getter::v
          returnType: int
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
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        requiredPositional _v
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer a @4
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: Never
          variable: #F1
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F4 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: Never
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: Never
      variable: <testLibrary>::@topLevelVariable::a
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 a @4
          element: <testLibrary>::@topLevelVariable::a
          getter: #F2
          setter: #F3
      getters
        #F2 synthetic a
          element: <testLibrary>::@getter::a
          returnType: dynamic
          variable: #F1
      setters
        #F3 synthetic a
          element: <testLibrary>::@setter::a
          formalParameters
            #F4 _a
              element: <testLibrary>::@setter::a::@formalParameter::_a
  topLevelVariables
    a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        requiredPositional _a
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 const new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        #F4 hasInitializer a @41
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
          getter: #F5
      getters
        #F5 synthetic a
          element: <testLibrary>::@getter::a
          returnType: A<int>
          variable: #F4
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      type: A<int>
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: A<int>
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_variables() async {
    var library = await buildLibrary('int i; int j;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 i @4
          element: <testLibrary>::@topLevelVariable::i
          getter: #F2
          setter: #F3
        #F4 j @11
          element: <testLibrary>::@topLevelVariable::j
          getter: #F5
          setter: #F6
      getters
        #F2 synthetic i
          element: <testLibrary>::@getter::i
          returnType: int
          variable: #F1
        #F5 synthetic j
          element: <testLibrary>::@getter::j
          returnType: int
          variable: #F4
      setters
        #F3 synthetic i
          element: <testLibrary>::@setter::i
          formalParameters
            #F7 _i
              element: <testLibrary>::@setter::i::@formalParameter::_i
        #F6 synthetic j
          element: <testLibrary>::@setter::j
          formalParameters
            #F8 _j
              element: <testLibrary>::@setter::j::@formalParameter::_j
  topLevelVariables
    i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::i
      setter: <testLibrary>::@setter::i
    j
      reference: <testLibrary>::@topLevelVariable::j
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::j
      setter: <testLibrary>::@setter::j
  getters
    synthetic static i
      reference: <testLibrary>::@getter::i
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::i
    synthetic static j
      reference: <testLibrary>::@getter::j
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::j
  setters
    synthetic static i
      reference: <testLibrary>::@setter::i
      firstFragment: #F3
      formalParameters
        requiredPositional _i
          firstFragment: #F7
          type: int
      returnType: void
    synthetic static j
      reference: <testLibrary>::@setter::j
      firstFragment: #F6
      formalParameters
        requiredPositional _j
          firstFragment: #F8
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
