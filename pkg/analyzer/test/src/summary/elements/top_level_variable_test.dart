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
    defineReflectiveTests(TopLevelVariableElementTest_augmentation_keepLinking);
    defineReflectiveTests(TopLevelVariableElementTest_augmentation_fromBytes);
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
        #F1 synthetic isOriginGetterSetter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::a
        #F2 synthetic isOriginGetterSetter b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@topLevelVariable::b
      getters
        #F3 isOriginDeclaration a (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::a
      setters
        #F4 isOriginDeclaration b (nameOffset:20) (firstTokenOffset:16) (offset:20)
          element: <testLibrary>::@setter::b
          formalParameters
            #F5 requiredPositional _ (nameOffset:26) (firstTokenOffset:22) (offset:26)
              element: <testLibrary>::@setter::b::@formalParameter::_
        #F6 isOriginDeclaration a (nameOffset:36) (firstTokenOffset:32) (offset:36)
          element: <testLibrary>::@setter::a
          formalParameters
            #F7 requiredPositional _ (nameOffset:42) (firstTokenOffset:38) (offset:42)
              element: <testLibrary>::@setter::a::@formalParameter::_
  topLevelVariables
    synthetic isOriginGetterSetter a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    synthetic isOriginGetterSetter b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: int
      setter: <testLibrary>::@setter::b
  getters
    static isOriginDeclaration a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
  setters
    static isOriginDeclaration b
      reference: <testLibrary>::@setter::b
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F5
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
    static isOriginDeclaration a
      reference: <testLibrary>::@setter::a
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional _
          firstFragment: #F7
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
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
        #F1 synthetic isOriginGetterSetter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@topLevelVariable::a
        #F2 synthetic isOriginGetterSetter b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@topLevelVariable::b
      getters
        #F3 isOriginDeclaration b (nameOffset:24) (firstTokenOffset:16) (offset:24)
          element: <testLibrary>::@getter::b
        #F4 isOriginDeclaration a (nameOffset:40) (firstTokenOffset:32) (offset:40)
          element: <testLibrary>::@getter::a
      setters
        #F5 isOriginDeclaration a (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F6 requiredPositional _ (nameOffset:10) (firstTokenOffset:6) (offset:10)
              element: <testLibrary>::@setter::a::@formalParameter::_
  topLevelVariables
    synthetic isOriginGetterSetter a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    synthetic isOriginGetterSetter b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::b
  getters
    static isOriginDeclaration b
      reference: <testLibrary>::@getter::b
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
    static isOriginDeclaration a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
  setters
    static isOriginDeclaration a
      reference: <testLibrary>::@setter::a
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
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
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isOriginDeclaration foo (nameOffset:16) (firstTokenOffset:0) (offset:16)
          element: <testLibrary>::@getter::foo
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: Future<int>
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginDeclaration foo
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
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isOriginDeclaration foo (nameOffset:37) (firstTokenOffset:21) (offset:37)
          element: <testLibrary>::@getter::foo
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: Stream<int>
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginDeclaration foo
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
        #F1 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 isOriginDeclaration x (nameOffset:64) (firstTokenOffset:44) (offset:64)
          element: <testLibrary>::@getter::x
          documentationComment: /**\n * Docs\n */
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::x
  getters
    static isOriginDeclaration x
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
        #F1 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 isOriginDeclaration x (nameOffset:17) (firstTokenOffset:0) (offset:17)
          element: <testLibrary>::@getter::x
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
  getters
    static external isOriginDeclaration x
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
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 synthetic isOriginGetterSetter f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 synthetic isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isOriginDeclaration f (nameOffset:24) (firstTokenOffset:20) (offset:24)
              element: <testLibrary>::@class::C::@getter::f
        #F5 class D (nameOffset:52) (firstTokenOffset:37) (offset:52)
          element: <testLibrary>::@class::D
          fields
            #F6 synthetic isOriginGetterSetter f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@class::D::@field::f
          constructors
            #F7 synthetic isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F8 isOriginDeclaration f (nameOffset:64) (firstTokenOffset:56) (offset:64)
              element: <testLibrary>::@class::D::@getter::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      fields
        synthetic isOriginGetterSetter f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        synthetic isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          superConstructor: <testLibrary>::@class::D::@constructor::new
      getters
        isOriginDeclaration f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::f
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: #F5
      fields
        synthetic isOriginGetterSetter f
          reference: <testLibrary>::@class::D::@field::f
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::D::@getter::f
      constructors
        synthetic isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F7
      getters
        abstract isOriginDeclaration f
          reference: <testLibrary>::@class::D::@getter::f
          firstFragment: #F8
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
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isOriginDeclaration foo (nameOffset:18) (firstTokenOffset:0) (offset:18)
          element: <testLibrary>::@getter::foo
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: Iterator<int>
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginDeclaration foo
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
        #F1 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::x
        #F2 synthetic isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@topLevelVariable::y
      getters
        #F3 isOriginDeclaration x (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::x
        #F4 isOriginDeclaration y (nameOffset:23) (firstTokenOffset:19) (offset:23)
          element: <testLibrary>::@getter::y
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
    synthetic isOriginGetterSetter y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::y
  getters
    static isOriginDeclaration x
      reference: <testLibrary>::@getter::x
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
    static isOriginDeclaration y
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 isOriginDeclaration x (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::x
      setters
        #F3 isOriginDeclaration x (nameOffset:25) (firstTokenOffset:16) (offset:25)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:31) (firstTokenOffset:27) (offset:31)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginDeclaration x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginDeclaration x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 isOriginDeclaration x (nameOffset:33) (firstTokenOffset:25) (offset:33)
          element: <testLibrary>::@getter::x
      setters
        #F3 isOriginDeclaration x (nameOffset:9) (firstTokenOffset:0) (offset:9)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:15) (firstTokenOffset:11) (offset:15)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginDeclaration x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginDeclaration x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
          element: <testLibrary>::@topLevelVariable::x
      setters
        #F2 isOriginDeclaration x (nameOffset:69) (firstTokenOffset:44) (offset:69)
          element: <testLibrary>::@setter::x
          documentationComment: /**\n * Docs\n */
          formalParameters
            #F3 requiredPositional value (nameOffset:71) (firstTokenOffset:71) (offset:71)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: dynamic
      setter: <testLibrary>::@setter::x
  setters
    static isOriginDeclaration x
      reference: <testLibrary>::@setter::x
      firstFragment: #F2
      documentationComment: /**\n * Docs\n */
      formalParameters
        #E0 requiredPositional hasImplicitType value
          firstFragment: #F3
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@topLevelVariable::x
      setters
        #F2 isOriginDeclaration x (nameOffset:18) (firstTokenOffset:0) (offset:18)
          element: <testLibrary>::@setter::x
          formalParameters
            #F3 requiredPositional value (nameOffset:24) (firstTokenOffset:20) (offset:24)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::x
  setters
    static external isOriginDeclaration x
      reference: <testLibrary>::@setter::x
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F3
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 synthetic isOriginGetterSetter f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@topLevelVariable::f
      setters
        #F2 isOriginDeclaration f (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@setter::f
          formalParameters
            #F3 requiredPositional value (nameOffset:10) (firstTokenOffset:6) (offset:10)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    synthetic isOriginGetterSetter f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::f
  setters
    static isOriginDeclaration f
      reference: <testLibrary>::@setter::f
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F3
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
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
        #F1 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
          element: <testLibrary>::@topLevelVariable::x
        #F2 synthetic isOriginGetterSetter y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@topLevelVariable::y
      setters
        #F3 isOriginDeclaration x (nameOffset:9) (firstTokenOffset:0) (offset:9)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:15) (firstTokenOffset:11) (offset:15)
              element: <testLibrary>::@setter::x::@formalParameter::value
        #F5 isOriginDeclaration y (nameOffset:29) (firstTokenOffset:25) (offset:29)
          element: <testLibrary>::@setter::y
          formalParameters
            #F6 requiredPositional value (nameOffset:31) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@setter::y::@formalParameter::value
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::x
    synthetic isOriginGetterSetter y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F2
      type: dynamic
      setter: <testLibrary>::@setter::y
  setters
    static isOriginDeclaration x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
    static isOriginDeclaration y
      reference: <testLibrary>::@setter::y
      firstFragment: #F5
      formalParameters
        #E1 requiredPositional hasImplicitType value
          firstFragment: #F6
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::y
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
        #F1 isOriginDeclaration i (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::i
      getters
        #F2 synthetic isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::i
      setters
        #F3 synthetic isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@setter::i
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@setter::i::@formalParameter::value
  topLevelVariables
    external isOriginDeclaration i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::i
      setter: <testLibrary>::@setter::i
  getters
    synthetic static isOriginVariable i
      reference: <testLibrary>::@getter::i
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::i
  setters
    synthetic static isOriginVariable i
      reference: <testLibrary>::@setter::i
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::i
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
        #F1 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 isOriginDeclaration x (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::x
      setters
        #F3 isOriginDeclaration x (nameOffset:25) (firstTokenOffset:16) (offset:25)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:31) (firstTokenOffset:27) (offset:31)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginDeclaration x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginDeclaration x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 isOriginDeclaration x (nameOffset:33) (firstTokenOffset:25) (offset:33)
          element: <testLibrary>::@getter::x
      setters
        #F3 isOriginDeclaration x (nameOffset:9) (firstTokenOffset:0) (offset:9)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:15) (firstTokenOffset:11) (offset:15)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginDeclaration x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginDeclaration x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_unit_variable_duplicate() async {
    var library = await buildLibrary('''
int foo = 0;
int foo = 1;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo::@def::0
        #F2 hasInitializer isOriginDeclaration foo (nameOffset:17) (firstTokenOffset:17) (offset:17)
          element: <testLibrary>::@topLevelVariable::foo::@def::1
      getters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo::@def::0
        #F4 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@getter::foo::@def::1
      setters
        #F5 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo::@def::0
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@def::0::@formalParameter::value
        #F7 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@setter::foo::@def::1
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@setter::foo::@def::1::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::0
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo::@def::0
      setter: <testLibrary>::@setter::foo::@def::0
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::1
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::foo::@def::1
      setter: <testLibrary>::@setter::foo::@def::1
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo::@def::0
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo::@def::0
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo::@def::1
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo::@def::1
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo::@def::0
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo::@def::0
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo::@def::1
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo::@def::1
''');
  }

  test_unit_variable_duplicate_getter() async {
    var library = await buildLibrary('''
int foo = 0;
int get foo => 0;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo::@def::0
        #F2 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@topLevelVariable::foo::@def::1
      getters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo::@def::0
        #F4 isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:13) (offset:21)
          element: <testLibrary>::@getter::foo::@def::1
      setters
        #F5 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::0
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo::@def::0
      setter: <testLibrary>::@setter::foo
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::1
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::foo::@def::1
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo::@def::0
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo::@def::0
    static isOriginDeclaration foo
      reference: <testLibrary>::@getter::foo::@def::1
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo::@def::1
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo::@def::0
''');
  }

  test_unit_variable_duplicate_setter() async {
    var library = await buildLibrary('''
int foo = 0;
set foo(int _) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo::@def::0
        #F2 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@topLevelVariable::foo::@def::1
      getters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo
      setters
        #F4 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo::@def::0
          formalParameters
            #F5 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@def::0::@formalParameter::value
        #F6 isOriginDeclaration foo (nameOffset:17) (firstTokenOffset:13) (offset:17)
          element: <testLibrary>::@setter::foo::@def::1
          formalParameters
            #F7 requiredPositional _ (nameOffset:25) (firstTokenOffset:21) (offset:25)
              element: <testLibrary>::@setter::foo::@def::1::@formalParameter::_
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::0
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo::@def::0
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::1
      firstFragment: #F2
      type: int
      setter: <testLibrary>::@setter::foo::@def::1
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo::@def::0
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo::@def::0
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F5
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo::@def::0
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo::@def::1
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional _
          firstFragment: #F7
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo::@def::1
''');
  }

  test_unit_variable_final_withSetter() async {
    var library = await buildLibrary(r'''
final int foo = 0;
set foo(int newValue) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::foo
      setters
        #F3 isOriginDeclaration foo (nameOffset:23) (firstTokenOffset:19) (offset:23)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional newValue (nameOffset:31) (firstTokenOffset:27) (offset:31)
              element: <testLibrary>::@setter::foo::@formalParameter::newValue
  topLevelVariables
    final hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional newValue
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
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
        #F1 hasInitializer isOriginDeclaration x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 hasInitializer isOriginDeclaration i (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::i
          initializer: expression_0
            IntegerLiteral
              literal: 0 @14
              staticType: int
      getters
        #F2 synthetic isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::i
  topLevelVariables
    const hasInitializer isOriginDeclaration i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::i
  getters
    synthetic static isOriginVariable i
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
        #F1 hasInitializer isOriginDeclaration i (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::i
          initializer: expression_0
            IntegerLiteral
              literal: 0 @19
              staticType: int
      getters
        #F2 synthetic isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::i
  topLevelVariables
    late const hasInitializer isOriginDeclaration i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::i
  getters
    synthetic static isOriginVariable i
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
        #F1 isOriginDeclaration x (nameOffset:64) (firstTokenOffset:64) (offset:64)
          element: <testLibrary>::@topLevelVariable::x
          documentationComment: /**\n * Docs\n */
      getters
        #F2 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      documentationComment: /**\n * Docs\n */
      type: dynamic
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 hasInitializer isOriginDeclaration x (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::x
  topLevelVariables
    final hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
  getters
    synthetic static isOriginVariable x
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
        #F1 isOriginDeclaration foo (nameOffset:38) (firstTokenOffset:38) (offset:38)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
          element: <testLibrary>::@getter::foo
  topLevelVariables
    final isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int Function(int, {void Function() fn})?
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static isOriginVariable foo
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
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 16
          unit: #F1
      topLevelVariables
        #F2 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F3 isOriginDeclaration x (nameOffset:39) (firstTokenOffset:31) (offset:39)
          element: <testLibrary>::@getter::x
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      setters
        #F4 isOriginDeclaration x (nameOffset:25) (firstTokenOffset:16) (offset:25)
          element: <testLibrary>::@setter::x
          formalParameters
            #F5 requiredPositional _ (nameOffset:31) (firstTokenOffset:27) (offset:31)
              element: <testLibrary>::@setter::x::@formalParameter::_
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginDeclaration x
      reference: <testLibrary>::@getter::x
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginDeclaration x
      reference: <testLibrary>::@setter::x
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F5
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 16
          unit: #F1
      topLevelVariables
        #F2 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@topLevelVariable::x
      setters
        #F3 isOriginDeclaration x (nameOffset:40) (firstTokenOffset:31) (offset:40)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional _ (nameOffset:46) (firstTokenOffset:42) (offset:46)
              element: <testLibrary>::@setter::x::@formalParameter::_
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      getters
        #F5 isOriginDeclaration x (nameOffset:24) (firstTokenOffset:16) (offset:24)
          element: <testLibrary>::@getter::x
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginDeclaration x
      reference: <testLibrary>::@getter::x
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginDeclaration x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 16
          unit: #F1
        part_1
          uri: package:test/b.dart
          partKeywordOffset: 31
          unit: #F2
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F2
      topLevelVariables
        #F3 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F4 isOriginDeclaration x (nameOffset:24) (firstTokenOffset:16) (offset:24)
          element: <testLibrary>::@getter::x
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F1
      setters
        #F5 isOriginDeclaration x (nameOffset:25) (firstTokenOffset:16) (offset:25)
          element: <testLibrary>::@setter::x
          formalParameters
            #F6 requiredPositional _ (nameOffset:31) (firstTokenOffset:27) (offset:31)
              element: <testLibrary>::@setter::x::@formalParameter::_
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginDeclaration x
      reference: <testLibrary>::@getter::x
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginDeclaration x
      reference: <testLibrary>::@setter::x
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_variable_implicit() async {
    var library = await buildLibrary('int get x => 0;');

    // We intentionally don't check the text, because we want to test
    // requesting individual elements, not all accessors/variables at once.
    var getter = library.getters.single;
    var variable = getter.variable as TopLevelVariableElementImpl;
    expect(variable, isNotNull);
    expect(variable.isFinal, isFalse);
    expect(variable.getter, same(getter));
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
        #F1 isOriginDeclaration x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 hasInitializer isOriginDeclaration v (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static isOriginVariable v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
        #F1 hasInitializer isOriginDeclaration v (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::v
  topLevelVariables
    final hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::v
  getters
    synthetic static isOriginVariable v
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
        #F1 hasInitializer isOriginDeclaration v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
  topLevelVariables
    final hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::v
  getters
    synthetic static isOriginVariable v
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
        #F1 hasInitializer isOriginDeclaration x (nameOffset:6) (firstTokenOffset:6) (offset:6)
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
      getters
        #F2 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::x
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: (int, bool)
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    synthetic static isOriginVariable x
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      extensions
        #F3 extension E (nameOffset:21) (firstTokenOffset:11) (offset:21)
          element: <testLibrary>::@extension::E
          methods
            #F4 isOriginDeclaration f (nameOffset:43) (firstTokenOffset:32) (offset:43)
              element: <testLibrary>::@extension::E::@method::f
      topLevelVariables
        #F5 hasInitializer isOriginDeclaration x (nameOffset:59) (firstTokenOffset:59) (offset:59)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F6 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@getter::x
      setters
        #F7 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@setter::x
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F3
      extendedType: A
      onDeclaration: <testLibrary>::@class::A
      methods
        static isOriginDeclaration f
          reference: <testLibrary>::@extension::E::@method::f
          firstFragment: #F4
          returnType: int
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F5
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 hasInitializer isOriginDeclaration v (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static isOriginVariable v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
        #F1 hasInitializer isOriginDeclaration x (nameOffset:9) (firstTokenOffset:9) (offset:9)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    late hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 isOriginDeclaration x (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    late final isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static isOriginVariable x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static isOriginVariable x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
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
        #F1 hasInitializer isOriginDeclaration x (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::x
  topLevelVariables
    late final hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
  getters
    synthetic static isOriginVariable x
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
        #F1 isOriginDeclaration a (nameOffset:8) (firstTokenOffset:8) (offset:8)
          element: <testLibrary>::@topLevelVariable::a
        #F2 isOriginDeclaration <null-name> (nameOffset:<null>) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::0
      getters
        #F3 synthetic isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@getter::a
        #F4 synthetic isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::1
      setters
        #F5 synthetic isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@setter::a
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F7 synthetic isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@setter::2
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@setter::2::@formalParameter::value
  topLevelVariables
    isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: Object?
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    isOriginDeclaration <null-name>
      reference: <testLibrary>::@topLevelVariable::0
      firstFragment: #F2
      type: Object?
      getter: <testLibrary>::@getter::1
      setter: <testLibrary>::@setter::2
  getters
    synthetic static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: Object?
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static isOriginVariable <null-name>
      reference: <testLibrary>::@getter::1
      firstFragment: #F4
      returnType: Object?
      variable: <testLibrary>::@topLevelVariable::0
  setters
    synthetic static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: Object?
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static isOriginVariable <null-name>
      reference: <testLibrary>::@setter::2
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: Object?
      returnType: void
      variable: <testLibrary>::@topLevelVariable::0
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
        #F1 hasInitializer isOriginDeclaration i (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::i
          initializer: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
      getters
        #F2 synthetic isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::i
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::i
  getters
    synthetic static isOriginVariable i
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
        #F1 hasInitializer isOriginDeclaration b (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::b
      getters
        #F2 synthetic isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::b
  topLevelVariables
    final hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F1
      type: double
      getter: <testLibrary>::@getter::b
  getters
    synthetic static isOriginVariable b
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
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 13
          unit: #F1
      topLevelVariables
        #F2 hasInitializer isOriginDeclaration b (nameOffset:34) (firstTokenOffset:34) (offset:34)
          element: <testLibrary>::@topLevelVariable::b
      getters
        #F3 synthetic isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
          element: <testLibrary>::@getter::b
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      topLevelVariables
        #F4 hasInitializer isOriginDeclaration a (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::a
      getters
        #F5 synthetic isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::a
  topLevelVariables
    final hasImplicitType hasInitializer isOriginDeclaration b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::b
    final hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::a
  getters
    synthetic static isOriginVariable b
      reference: <testLibrary>::@getter::b
      firstFragment: #F3
      returnType: double
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static isOriginVariable a
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
        #F1 hasInitializer isOriginDeclaration i (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::i
      getters
        #F2 synthetic isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::i
  topLevelVariables
    final hasImplicitType hasInitializer isOriginDeclaration i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::i
  getters
    synthetic static isOriginVariable i
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
        #F1 hasInitializer isOriginDeclaration x (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::x
  topLevelVariables
    final hasImplicitType hasInitializer isOriginDeclaration x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::x
  getters
    synthetic static isOriginVariable x
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
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 16
          unit: #F1
        part_1
          uri: package:test/b.dart
          partKeywordOffset: 31
          unit: #F2
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F2
      topLevelVariables
        #F3 synthetic isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@topLevelVariable::x
      setters
        #F4 isOriginDeclaration x (nameOffset:25) (firstTokenOffset:16) (offset:25)
          element: <testLibrary>::@setter::x
          formalParameters
            #F5 requiredPositional _ (nameOffset:31) (firstTokenOffset:27) (offset:31)
              element: <testLibrary>::@setter::x::@formalParameter::_
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F1
      getters
        #F6 isOriginDeclaration x (nameOffset:24) (firstTokenOffset:16) (offset:24)
          element: <testLibrary>::@getter::x
  topLevelVariables
    synthetic isOriginGetterSetter x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    static isOriginDeclaration x
      reference: <testLibrary>::@getter::x
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    static isOriginDeclaration x
      reference: <testLibrary>::@setter::x
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F5
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_variable_type_dynamic() async {
    var library = await buildLibrary('dynamic v;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 isOriginDeclaration v (nameOffset:8) (firstTokenOffset:8) (offset:8)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static isOriginVariable v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
        #F1 hasInitializer isOriginDeclaration v (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static isOriginVariable v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static isOriginVariable v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
        #F1 hasInitializer isOriginDeclaration a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
      getters
        #F2 synthetic isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
      setters
        #F3 synthetic isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: Never
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
  getters
    synthetic static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: Never
      variable: <testLibrary>::@topLevelVariable::a
  setters
    synthetic static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Never
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
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
        #F1 isOriginDeclaration a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
      getters
        #F2 synthetic isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
      setters
        #F3 synthetic isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
  topLevelVariables
    hasImplicitType isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
  getters
    synthetic static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  setters
    synthetic static isOriginVariable a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_variable_type_invalidType_topLevelVariable() async {
    var library = await buildLibrary(r'''
final int foo = 0;
final foo bar;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::foo
        #F2 isOriginDeclaration bar (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::bar
      getters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::foo
        #F4 synthetic isOriginVariable bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::bar
  topLevelVariables
    final hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
    final isOriginDeclaration bar
      reference: <testLibrary>::@topLevelVariable::bar
      firstFragment: #F2
      type: InvalidType
      getter: <testLibrary>::@getter::bar
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
    synthetic static isOriginVariable bar
      reference: <testLibrary>::@getter::bar
      firstFragment: #F4
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::bar
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        #F4 hasInitializer isOriginDeclaration a (nameOffset:41) (firstTokenOffset:41) (offset:41)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: A @45
                  element: <testLibrary>::@class::A
                  type: A<int>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::A::@constructor::new
                  substitution: {T: int}
              argumentList: ArgumentList
                leftParenthesis: ( @46
                rightParenthesis: ) @47
              staticType: A<int>
      getters
        #F5 synthetic isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@getter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  topLevelVariables
    const hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      type: A<int>
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static isOriginVariable a
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
        #F1 isOriginDeclaration i (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::i
        #F2 isOriginDeclaration j (nameOffset:11) (firstTokenOffset:11) (offset:11)
          element: <testLibrary>::@topLevelVariable::j
      getters
        #F3 synthetic isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::i
        #F4 synthetic isOriginVariable j (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
          element: <testLibrary>::@getter::j
      setters
        #F5 synthetic isOriginVariable i (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::i
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::i::@formalParameter::value
        #F7 synthetic isOriginVariable j (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
          element: <testLibrary>::@setter::j
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@setter::j::@formalParameter::value
  topLevelVariables
    isOriginDeclaration i
      reference: <testLibrary>::@topLevelVariable::i
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::i
      setter: <testLibrary>::@setter::i
    isOriginDeclaration j
      reference: <testLibrary>::@topLevelVariable::j
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::j
      setter: <testLibrary>::@setter::j
  getters
    synthetic static isOriginVariable i
      reference: <testLibrary>::@getter::i
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::i
    synthetic static isOriginVariable j
      reference: <testLibrary>::@getter::j
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::j
  setters
    synthetic static isOriginVariable i
      reference: <testLibrary>::@setter::i
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::i
    synthetic static isOriginVariable j
      reference: <testLibrary>::@setter::j
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::j
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
  test_getter_augment_class() async {
    var library = await buildLibrary(r'''
class A {}
augment int get A => 0;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      topLevelVariables
        #F3 synthetic isOriginGetterSetter A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@topLevelVariable::A
      getters
        #F4 augment isOriginDeclaration A (nameOffset:27) (firstTokenOffset:11) (offset:27)
          element: <testLibrary>::@getter::A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  topLevelVariables
    synthetic isOriginGetterSetter A
      reference: <testLibrary>::@topLevelVariable::A
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::A
  getters
    static isOriginDeclaration A
      reference: <testLibrary>::@getter::A
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::A
  exportedReferences
    declared <testLibrary>::@getter::A
  exportNamespace
    A: <testLibrary>::@getter::A
''');
  }

  test_getter_augment_function() async {
    var library = await buildLibrary(r'''
void foo() {}
augment int get foo => 0;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 augment isOriginDeclaration foo (nameOffset:30) (firstTokenOffset:14) (offset:30)
          element: <testLibrary>::@getter::foo
      functions
        #F3 isOriginDeclaration foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginDeclaration foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  functions
    isOriginDeclaration foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F3
      returnType: void
  exportedReferences
    declared <testLibrary>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
''');
  }

  test_getter_augment_getter() async {
    var library = await buildLibrary(r'''
int get foo => 0;
augment int get foo => 1;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isOriginDeclaration foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::foo
          nextFragment: #F3
        #F3 augment isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:18) (offset:34)
          element: <testLibrary>::@getter::foo
          previousFragment: #F2
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginDeclaration foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
''');
  }

  test_getter_augment_getter_differentType() async {
    var library = await buildLibrary(r'''
int get foo => 0;
augment double get foo => 1;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isOriginDeclaration foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::foo
          nextFragment: #F3
        #F3 augment isOriginDeclaration foo (nameOffset:37) (firstTokenOffset:18) (offset:37)
          element: <testLibrary>::@getter::foo
          previousFragment: #F2
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginDeclaration foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
''');
  }

  test_getter_augment_getter_multiple_annotations() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a1 = 1;
const a2 = 2;
const a3 = 3;
''');

    var library = await buildLibrary(r'''
import 'a.dart';
@a1
int get foo => 0;
@a2
augment int get foo => 1;
@a3
augment int get foo => 2;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isOriginDeclaration foo (nameOffset:29) (firstTokenOffset:17) (offset:29)
          element: <testLibrary>::@getter::foo
          metadata
            Annotation
              atSign: @ @17
              name: SimpleIdentifier
                token: a1 @18
                element: package:test/a.dart::@getter::a1
                staticType: null
              element: package:test/a.dart::@getter::a1
          nextFragment: #F3
        #F3 augment isOriginDeclaration foo (nameOffset:59) (firstTokenOffset:39) (offset:59)
          element: <testLibrary>::@getter::foo
          metadata
            Annotation
              atSign: @ @39
              name: SimpleIdentifier
                token: a2 @40
                element: package:test/a.dart::@getter::a2
                staticType: null
              element: package:test/a.dart::@getter::a2
          previousFragment: #F2
          nextFragment: #F4
        #F4 augment isOriginDeclaration foo (nameOffset:89) (firstTokenOffset:69) (offset:89)
          element: <testLibrary>::@getter::foo
          metadata
            Annotation
              atSign: @ @69
              name: SimpleIdentifier
                token: a3 @70
                element: package:test/a.dart::@getter::a3
                staticType: null
              element: package:test/a.dart::@getter::a3
          previousFragment: #F3
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginDeclaration foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      metadata
        Annotation
          atSign: @ @17
          name: SimpleIdentifier
            token: a1 @18
            element: package:test/a.dart::@getter::a1
            staticType: null
          element: package:test/a.dart::@getter::a1
        Annotation
          atSign: @ @39
          name: SimpleIdentifier
            token: a2 @40
            element: package:test/a.dart::@getter::a2
            staticType: null
          element: package:test/a.dart::@getter::a2
        Annotation
          atSign: @ @69
          name: SimpleIdentifier
            token: a3 @70
            element: package:test/a.dart::@getter::a3
            staticType: null
          element: package:test/a.dart::@getter::a3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
''');
  }

  test_getter_augment_multiple_getters() async {
    var library = await buildLibrary(r'''
int get foo => 0;
augment int get foo => 1;
augment int get foo => 2;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isOriginDeclaration foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::foo
          nextFragment: #F3
        #F3 augment isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:18) (offset:34)
          element: <testLibrary>::@getter::foo
          previousFragment: #F2
          nextFragment: #F4
        #F4 augment isOriginDeclaration foo (nameOffset:60) (firstTokenOffset:44) (offset:60)
          element: <testLibrary>::@getter::foo
          previousFragment: #F3
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginDeclaration foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
''');
  }

  test_getter_augment_multiple_getters_differentType() async {
    var library = await buildLibrary(r'''
int get foo => 0;
augment int get foo => 1;
augment double get foo => 2;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isOriginDeclaration foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::foo
          nextFragment: #F3
        #F3 augment isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:18) (offset:34)
          element: <testLibrary>::@getter::foo
          previousFragment: #F2
          nextFragment: #F4
        #F4 augment isOriginDeclaration foo (nameOffset:63) (firstTokenOffset:44) (offset:63)
          element: <testLibrary>::@getter::foo
          previousFragment: #F3
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginDeclaration foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
''');
  }

  test_getter_augment_setter() async {
    var library = await buildLibrary(r'''
set foo(int _) {}
augment int get foo => 0;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 augment isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:18) (offset:34)
          element: <testLibrary>::@getter::foo
      setters
        #F3 isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional _ (nameOffset:12) (firstTokenOffset:8) (offset:12)
              element: <testLibrary>::@setter::foo::@formalParameter::_
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    static isOriginDeclaration foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_getter_augment_variable() async {
    var library = await buildLibrary(r'''
int foo = 0;
augment int get foo => 1;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo
          nextFragment: #F3
        #F3 augment isOriginDeclaration foo (nameOffset:29) (firstTokenOffset:13) (offset:29)
          element: <testLibrary>::@getter::foo
          previousFragment: #F2
      setters
        #F4 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F5 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F5
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_getter_augment_variable_annotated() async {
    var library = await buildLibrary(r'''
final foo = 0;
@deprecated
augment int get foo;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          nextFragment: #F3
        #F3 augment isOriginDeclaration foo (nameOffset:43) (firstTokenOffset:15) (offset:43)
          element: <testLibrary>::@getter::foo
          metadata
            Annotation
              atSign: @ @15
              name: SimpleIdentifier
                token: deprecated @16
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          previousFragment: #F2
  topLevelVariables
    final hasImplicitType hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      metadata
        Annotation
          atSign: @ @15
          name: SimpleIdentifier
            token: deprecated @16
            element: dart:core::@getter::deprecated
            staticType: null
          element: dart:core::@getter::deprecated
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
''');
  }

  test_getter_augment_variable_const() async {
    var library = await buildLibrary(r'''
const int foo = 0;
augment int get foo => 1;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @16
              staticType: int
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::foo
          nextFragment: #F3
        #F3 augment isOriginDeclaration foo (nameOffset:35) (firstTokenOffset:19) (offset:35)
          element: <testLibrary>::@getter::foo
          previousFragment: #F2
  topLevelVariables
    const hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_getter_augment_variable_differentType() async {
    var library = await buildLibrary(r'''
int foo = 0;
augment double get foo => 1;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo
          nextFragment: #F3
        #F3 augment isOriginDeclaration foo (nameOffset:32) (firstTokenOffset:13) (offset:32)
          element: <testLibrary>::@getter::foo
          previousFragment: #F2
      setters
        #F4 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F5 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F5
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_getter_augment_variable_final() async {
    var library = await buildLibrary(r'''
final int foo = 0;
augment int get foo => 1;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::foo
          nextFragment: #F3
        #F3 augment isOriginDeclaration foo (nameOffset:35) (firstTokenOffset:19) (offset:35)
          element: <testLibrary>::@getter::foo
          previousFragment: #F2
  topLevelVariables
    final hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
''');
  }

  test_setter_augment_class() async {
    var library = await buildLibrary(r'''
class A {}
augment set A(int _) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      topLevelVariables
        #F3 synthetic isOriginGetterSetter A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@topLevelVariable::A
      setters
        #F4 augment isOriginDeclaration A (nameOffset:23) (firstTokenOffset:11) (offset:23)
          element: <testLibrary>::@setter::A
          formalParameters
            #F5 requiredPositional _ (nameOffset:29) (firstTokenOffset:25) (offset:29)
              element: <testLibrary>::@setter::A::@formalParameter::_
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  topLevelVariables
    synthetic isOriginGetterSetter A
      reference: <testLibrary>::@topLevelVariable::A
      firstFragment: #F3
      type: int
      setter: <testLibrary>::@setter::A
  setters
    static isOriginDeclaration A
      reference: <testLibrary>::@setter::A
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F5
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::A
  exportedReferences
    declared <testLibrary>::@class::A
    declared <testLibrary>::@setter::A
  exportNamespace
    A: <testLibrary>::@class::A
    A=: <testLibrary>::@setter::A
''');
  }

  test_setter_augment_function() async {
    var library = await buildLibrary(r'''
void foo() {}
augment set foo(int _) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@topLevelVariable::foo
      setters
        #F2 augment isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:14) (offset:26)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F3 requiredPositional _ (nameOffset:34) (firstTokenOffset:30) (offset:34)
              element: <testLibrary>::@setter::foo::@formalParameter::_
      functions
        #F4 isOriginDeclaration foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F3
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  functions
    isOriginDeclaration foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F4
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_setter_augment_getter() async {
    var library = await buildLibrary(r'''
int get foo => 0;
augment set foo(int _) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isOriginDeclaration foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::foo
      setters
        #F3 augment isOriginDeclaration foo (nameOffset:30) (firstTokenOffset:18) (offset:30)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional _ (nameOffset:38) (firstTokenOffset:34) (offset:38)
              element: <testLibrary>::@setter::foo::@formalParameter::_
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    static isOriginDeclaration foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_setter_augment_getter_differentType() async {
    var library = await buildLibrary(r'''
int get foo => 0;
augment set foo(double _) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isOriginDeclaration foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::foo
      setters
        #F3 augment isOriginDeclaration foo (nameOffset:30) (firstTokenOffset:18) (offset:30)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional _ (nameOffset:41) (firstTokenOffset:34) (offset:41)
              element: <testLibrary>::@setter::foo::@formalParameter::_
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    static isOriginDeclaration foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F4
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_setter_augment_getter_multiple_annotations() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a1 = 1;
const a2 = 2;
const a3 = 3;
''');

    var library = await buildLibrary(r'''
import 'a.dart';
@a1
set foo(int _) {}
@a2
augment set foo(int _) {}
@a3
augment set foo(int _) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@topLevelVariable::foo
      setters
        #F2 isOriginDeclaration foo (nameOffset:25) (firstTokenOffset:17) (offset:25)
          element: <testLibrary>::@setter::foo
          metadata
            Annotation
              atSign: @ @17
              name: SimpleIdentifier
                token: a1 @18
                element: package:test/a.dart::@getter::a1
                staticType: null
              element: package:test/a.dart::@getter::a1
          formalParameters
            #F3 requiredPositional _ (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          nextFragment: #F4
        #F4 augment isOriginDeclaration foo (nameOffset:55) (firstTokenOffset:39) (offset:55)
          element: <testLibrary>::@setter::foo
          metadata
            Annotation
              atSign: @ @39
              name: SimpleIdentifier
                token: a2 @40
                element: package:test/a.dart::@getter::a2
                staticType: null
              element: package:test/a.dart::@getter::a2
          formalParameters
            #F5 requiredPositional _ (nameOffset:63) (firstTokenOffset:59) (offset:63)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          previousFragment: #F2
          nextFragment: #F6
        #F6 augment isOriginDeclaration foo (nameOffset:85) (firstTokenOffset:69) (offset:85)
          element: <testLibrary>::@setter::foo
          metadata
            Annotation
              atSign: @ @69
              name: SimpleIdentifier
                token: a3 @70
                element: package:test/a.dart::@getter::a3
                staticType: null
              element: package:test/a.dart::@getter::a3
          formalParameters
            #F7 requiredPositional _ (nameOffset:93) (firstTokenOffset:89) (offset:93)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          previousFragment: #F4
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F2
      metadata
        Annotation
          atSign: @ @17
          name: SimpleIdentifier
            token: a1 @18
            element: package:test/a.dart::@getter::a1
            staticType: null
          element: package:test/a.dart::@getter::a1
        Annotation
          atSign: @ @39
          name: SimpleIdentifier
            token: a2 @40
            element: package:test/a.dart::@getter::a2
            staticType: null
          element: package:test/a.dart::@getter::a2
        Annotation
          atSign: @ @69
          name: SimpleIdentifier
            token: a3 @70
            element: package:test/a.dart::@getter::a3
            staticType: null
          element: package:test/a.dart::@getter::a3
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F3
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_setter_augment_multiple_setters() async {
    var library = await buildLibrary(r'''
int set foo(int _) {}
augment set foo(int _) {}
augment set foo(int _) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
      setters
        #F2 isOriginDeclaration foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F3 requiredPositional _ (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          nextFragment: #F4
        #F4 augment isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:22) (offset:34)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F5 requiredPositional _ (nameOffset:42) (firstTokenOffset:38) (offset:42)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          previousFragment: #F2
          nextFragment: #F6
        #F6 augment isOriginDeclaration foo (nameOffset:60) (firstTokenOffset:48) (offset:60)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F7 requiredPositional _ (nameOffset:68) (firstTokenOffset:64) (offset:68)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          previousFragment: #F4
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F3
          type: int
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_setter_augment_multiple_setters_differentType() async {
    var library = await buildLibrary(r'''
int set foo(int _) {}
augment set foo(int _) {}
augment set foo(double _) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
      setters
        #F2 isOriginDeclaration foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F3 requiredPositional _ (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          nextFragment: #F4
        #F4 augment isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:22) (offset:34)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F5 requiredPositional _ (nameOffset:42) (firstTokenOffset:38) (offset:42)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          previousFragment: #F2
          nextFragment: #F6
        #F6 augment isOriginDeclaration foo (nameOffset:60) (firstTokenOffset:48) (offset:60)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F7 requiredPositional _ (nameOffset:71) (firstTokenOffset:64) (offset:71)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          previousFragment: #F4
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F3
          type: int
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_setter_augment_setter() async {
    var library = await buildLibrary(r'''
set foo(int _) {}
augment set foo(int _) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
      setters
        #F2 isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F3 requiredPositional _ (nameOffset:12) (firstTokenOffset:8) (offset:12)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          nextFragment: #F4
        #F4 augment isOriginDeclaration foo (nameOffset:30) (firstTokenOffset:18) (offset:30)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F5 requiredPositional _ (nameOffset:38) (firstTokenOffset:34) (offset:38)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          previousFragment: #F2
  topLevelVariables
    synthetic isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F3
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_setter_augment_variable() async {
    var library = await buildLibrary(r'''
int foo = 0;
augment set foo(int _) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo
      setters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@formalParameter::value
          nextFragment: #F5
        #F5 augment isOriginDeclaration foo (nameOffset:25) (firstTokenOffset:13) (offset:25)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F6 requiredPositional _ (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          previousFragment: #F3
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_setter_augment_variable_annotated() async {
    var library = await buildLibrary(r'''
final foo = 0;
@deprecated
augment set foo(int _) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
      setters
        #F3 augment isOriginDeclaration foo (nameOffset:39) (firstTokenOffset:15) (offset:39)
          element: <testLibrary>::@setter::foo
          metadata
            Annotation
              atSign: @ @15
              name: SimpleIdentifier
                token: deprecated @16
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          formalParameters
            #F4 requiredPositional _ (nameOffset:47) (firstTokenOffset:43) (offset:47)
              element: <testLibrary>::@setter::foo::@formalParameter::_
  topLevelVariables
    final hasImplicitType hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      metadata
        Annotation
          atSign: @ @15
          name: SimpleIdentifier
            token: deprecated @16
            element: dart:core::@getter::deprecated
            staticType: null
          element: dart:core::@getter::deprecated
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_setter_augment_variable_const() async {
    var library = await buildLibrary(r'''
const int foo = 0;
augment set foo(int _) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @16
              staticType: int
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::foo
      setters
        #F3 augment isOriginDeclaration foo (nameOffset:31) (firstTokenOffset:19) (offset:31)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional _ (nameOffset:39) (firstTokenOffset:35) (offset:39)
              element: <testLibrary>::@setter::foo::@formalParameter::_
  topLevelVariables
    const hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_setter_augment_variable_differentType() async {
    var library = await buildLibrary(r'''
int foo = 0;
augment set foo(double _) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo
      setters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@formalParameter::value
          nextFragment: #F5
        #F5 augment isOriginDeclaration foo (nameOffset:25) (firstTokenOffset:13) (offset:25)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F6 requiredPositional _ (nameOffset:36) (firstTokenOffset:29) (offset:36)
              element: <testLibrary>::@setter::foo::@formalParameter::_
          previousFragment: #F3
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_setter_augment_variable_final() async {
    var library = await buildLibrary(r'''
final int foo = 0;
augment set foo(int _) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::foo
      setters
        #F3 augment isOriginDeclaration foo (nameOffset:31) (firstTokenOffset:19) (offset:31)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional _ (nameOffset:39) (firstTokenOffset:35) (offset:39)
              element: <testLibrary>::@setter::foo::@formalParameter::_
  topLevelVariables
    final hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_variable_augment_class() async {
    var library = await buildLibrary(r'''
class A {}
augment int A = 0;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      topLevelVariables
        #F3 augment hasInitializer isOriginDeclaration A (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::A
      getters
        #F4 synthetic isOriginVariable A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::A
      setters
        #F5 synthetic isOriginVariable A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@setter::A
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@setter::A::@formalParameter::value
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  topLevelVariables
    hasInitializer isOriginDeclaration A
      reference: <testLibrary>::@topLevelVariable::A
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::A
      setter: <testLibrary>::@setter::A
  getters
    synthetic static isOriginVariable A
      reference: <testLibrary>::@getter::A
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::A
  setters
    synthetic static isOriginVariable A
      reference: <testLibrary>::@setter::A
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::A
  exportedReferences
    declared <testLibrary>::@getter::A
    declared <testLibrary>::@setter::A
  exportNamespace
    A: <testLibrary>::@getter::A
    A=: <testLibrary>::@setter::A
''');
  }

  test_variable_augment_function() async {
    var library = await buildLibrary(r'''
void foo() {}
augment int foo = 0;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 augment hasInitializer isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::foo
      setters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@setter::foo::@formalParameter::value
      functions
        #F5 isOriginDeclaration foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  functions
    isOriginDeclaration foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F5
      returnType: void
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_variable_augment_getter() async {
    var library = await buildLibrary(r'''
int get foo => 0;
augment int foo = 0;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
          nextFragment: #F2
        #F2 augment hasInitializer isOriginDeclaration foo (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: #F1
      getters
        #F3 isOriginDeclaration foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::foo
  topLevelVariables
    synthetic hasInitializer isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginDeclaration foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
''');
  }

  test_variable_augment_multiple_variables() async {
    var library = await buildLibrary(r'''
int foo = 0;
augment int foo = 1;
augment int foo = 2;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
          nextFragment: #F2
        #F2 augment hasInitializer isOriginDeclaration foo (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: #F1
          nextFragment: #F3
        #F3 augment hasInitializer isOriginDeclaration foo (nameOffset:46) (firstTokenOffset:46) (offset:46)
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: #F2
      getters
        #F4 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo
      setters
        #F5 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_variable_augment_multiple_variables_different_type() async {
    var library = await buildLibrary(r'''
int foo = 0;
augment int foo = 1;
augment double foo;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
          nextFragment: #F2
        #F2 augment hasInitializer isOriginDeclaration foo (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: #F1
          nextFragment: #F3
        #F3 augment isOriginDeclaration foo (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: #F2
      getters
        #F4 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo
      setters
        #F5 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_variable_augment_setter() async {
    var library = await buildLibrary(r'''
set foo(int _) {}
augment int foo = 0;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
          nextFragment: #F2
        #F2 augment hasInitializer isOriginDeclaration foo (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: #F1
      setters
        #F3 isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional _ (nameOffset:12) (firstTokenOffset:8) (offset:12)
              element: <testLibrary>::@setter::foo::@formalParameter::_
  topLevelVariables
    synthetic hasInitializer isOriginGetterSetter foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::foo
  setters
    static isOriginDeclaration foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_variable_augment_variable() async {
    var library = await buildLibrary(r'''
int foo = 0;
augment int foo = 1;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
          nextFragment: #F2
        #F2 augment hasInitializer isOriginDeclaration foo (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: #F1
      getters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo
      setters
        #F4 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F5 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F5
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_variable_augment_variable_annotated() async {
    var library = await buildLibrary(r'''
final foo = 0;
@deprecated
augment final foo;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          nextFragment: #F2
        #F2 augment isOriginDeclaration foo (nameOffset:41) (firstTokenOffset:41) (offset:41)
          element: <testLibrary>::@topLevelVariable::foo
          metadata
            Annotation
              atSign: @ @15
              name: SimpleIdentifier
                token: deprecated @16
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          previousFragment: #F1
      getters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  topLevelVariables
    final hasImplicitType hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      metadata
        Annotation
          atSign: @ @15
          name: SimpleIdentifier
            token: deprecated @16
            element: dart:core::@getter::deprecated
            staticType: null
          element: dart:core::@getter::deprecated
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
''');
  }

  test_variable_augment_variable_augmented_const() async {
    var library = await buildLibrary(r'''
const int foo = 0;
augment const int foo = 1;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_0
            IntegerLiteral
              literal: 0 @16
              staticType: null
          nextFragment: #F2
        #F2 augment hasInitializer isOriginDeclaration foo (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_1
            IntegerLiteral
              literal: 1 @43
              staticType: int
          previousFragment: #F1
      getters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::foo
  topLevelVariables
    const hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_1
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_variable_augment_variable_differentType() async {
    var library = await buildLibrary(r'''
int foo = 0;
augment double foo;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
          nextFragment: #F2
        #F2 augment isOriginDeclaration foo (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: #F1
      getters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo
      setters
        #F4 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F5 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F5
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
''');
  }

  test_variable_augment_variable_final() async {
    var library = await buildLibrary(r'''
final int foo = 0;
augment int foo = 1;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration foo (nameOffset:10) (firstTokenOffset:10) (offset:10)
          element: <testLibrary>::@topLevelVariable::foo
          nextFragment: #F2
        #F2 augment hasInitializer isOriginDeclaration foo (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: #F1
      getters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
          element: <testLibrary>::@getter::foo
  topLevelVariables
    final hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
''');
  }

  test_variable_augment_variable_initializer() async {
    var library = await buildLibrary(r'''
int foo;
augment int foo = 0;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 isOriginDeclaration foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
          nextFragment: #F2
        #F2 augment hasInitializer isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::foo
          previousFragment: #F1
      getters
        #F3 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo
      setters
        #F4 synthetic isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F5 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    synthetic static isOriginVariable foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F5
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  exportedReferences
    declared <testLibrary>::@getter::foo
    declared <testLibrary>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@getter::foo
    foo=: <testLibrary>::@setter::foo
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
