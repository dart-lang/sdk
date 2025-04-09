// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonSyntheticElementTest_keepLinking);
    defineReflectiveTests(NonSyntheticElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class NonSyntheticElementTest extends ElementsBaseTest {
  test_nonSynthetic_class_field() async {
    var library = await buildLibrary(r'''
class C {
  int foo = 0;
}
''');
    configuration.withNonSynthetic = true;
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
            hasInitializer foo @16
              reference: <testLibraryFragment>::@class::C::@field::foo
              element: <testLibraryFragment>::@class::C::@field::foo#element
              getter2: <testLibraryFragment>::@class::C::@getter::foo
              setter2: <testLibraryFragment>::@class::C::@setter::foo
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@class::C::@getter::foo
              element: <testLibraryFragment>::@class::C::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@class::C::@setter::foo
              element: <testLibraryFragment>::@class::C::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@class::C::@setter::foo::@parameter::_foo#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        hasInitializer foo
          firstFragment: <testLibraryFragment>::@class::C::@field::foo
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::foo#element
          setter: <testLibraryFragment>::@class::C::@setter::foo#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::C::@getter::foo
          returnType: int
      setters
        synthetic set foo
          firstFragment: <testLibraryFragment>::@class::C::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
          returnType: void
''');
  }

  test_nonSynthetic_class_getter() async {
    var library = await buildLibrary(r'''
class C {
  int get foo => 0;
}
''');
    configuration.withNonSynthetic = true;
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
            synthetic foo
              reference: <testLibraryFragment>::@class::C::@field::foo
              element: <testLibraryFragment>::@class::C::@field::foo#element
              getter2: <testLibraryFragment>::@class::C::@getter::foo
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            get foo @20
              reference: <testLibraryFragment>::@class::C::@getter::foo
              element: <testLibraryFragment>::@class::C::@getter::foo#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@class::C::@field::foo
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::foo#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        get foo
          firstFragment: <testLibraryFragment>::@class::C::@getter::foo
          returnType: int
''');
  }

  test_nonSynthetic_class_setter() async {
    var library = await buildLibrary(r'''
class C {
  set foo(int value) {}
}
''');
    configuration.withNonSynthetic = true;
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
            synthetic foo
              reference: <testLibraryFragment>::@class::C::@field::foo
              element: <testLibraryFragment>::@class::C::@field::foo#element
              setter2: <testLibraryFragment>::@class::C::@setter::foo
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          setters
            set foo @16
              reference: <testLibraryFragment>::@class::C::@setter::foo
              element: <testLibraryFragment>::@class::C::@setter::foo#element
              formalParameters
                value @24
                  element: <testLibraryFragment>::@class::C::@setter::foo::@parameter::value#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@class::C::@field::foo
          type: int
          setter: <testLibraryFragment>::@class::C::@setter::foo#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      setters
        set foo
          firstFragment: <testLibraryFragment>::@class::C::@setter::foo
          formalParameters
            requiredPositional value
              type: int
          returnType: void
''');
  }

  test_nonSynthetic_enum() async {
    var library = await buildLibrary(r'''
enum E {
  a, b
}
''');
    configuration.withNonSynthetic = true;
    checkElementText(library, r'''
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
            hasInitializer a @11
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <testLibraryFragment>::@enum::E::@field::a#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            hasInitializer b @14
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <testLibraryFragment>::@enum::E::@field::b#element
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            synthetic values
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      element: <testLibraryFragment>::@enum::E::@getter::a#element
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      element: <testLibraryFragment>::@enum::E::@getter::b#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              typeName: E
          getters
            synthetic get a
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <testLibraryFragment>::@enum::E::@getter::a#element
            synthetic get b
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <testLibraryFragment>::@enum::E::@getter::b#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const enumConstant hasInitializer a
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::a
            expression: expression_0
          getter: <testLibraryFragment>::@enum::E::@getter::a#element
        static const enumConstant hasInitializer b
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          type: E
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::b
            expression: expression_1
          getter: <testLibraryFragment>::@enum::E::@getter::b#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::E::@field::values
            expression: expression_2
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
          returnType: E
        synthetic static get b
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
          returnType: E
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
          returnType: List<E>
''');
  }

  test_nonSynthetic_mixin_field() async {
    var library = await buildLibrary(r'''
mixin M {
  int foo = 0;
}
''');
    configuration.withNonSynthetic = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
          fields
            hasInitializer foo @16
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <testLibraryFragment>::@mixin::M::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::M::@getter::foo
              setter2: <testLibraryFragment>::@mixin::M::@setter::foo
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              element: <testLibraryFragment>::@mixin::M::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@mixin::M::@setter::foo
              element: <testLibraryFragment>::@mixin::M::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@mixin::M::@setter::foo::@parameter::_foo#element
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        hasInitializer foo
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::M::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::M::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::foo
          returnType: int
      setters
        synthetic set foo
          firstFragment: <testLibraryFragment>::@mixin::M::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
          returnType: void
''');
  }

  test_nonSynthetic_mixin_getter() async {
    var library = await buildLibrary(r'''
mixin M {
  int get foo => 0;
}
''');
    configuration.withNonSynthetic = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
          fields
            synthetic foo
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <testLibraryFragment>::@mixin::M::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::M::@getter::foo
          getters
            get foo @20
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              element: <testLibraryFragment>::@mixin::M::@getter::foo#element
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::M::@getter::foo#element
      getters
        get foo
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::foo
          returnType: int
''');
  }

  test_nonSynthetic_mixin_setter() async {
    var library = await buildLibrary(r'''
mixin M {
  set foo(int value) {}
}
''');
    configuration.withNonSynthetic = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
          fields
            synthetic foo
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <testLibraryFragment>::@mixin::M::@field::foo#element
              setter2: <testLibraryFragment>::@mixin::M::@setter::foo
          setters
            set foo @16
              reference: <testLibraryFragment>::@mixin::M::@setter::foo
              element: <testLibraryFragment>::@mixin::M::@setter::foo#element
              formalParameters
                value @24
                  element: <testLibraryFragment>::@mixin::M::@setter::foo::@parameter::value#element
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          type: int
          setter: <testLibraryFragment>::@mixin::M::@setter::foo#element
      setters
        set foo
          firstFragment: <testLibraryFragment>::@mixin::M::@setter::foo
          formalParameters
            requiredPositional value
              type: int
          returnType: void
''');
  }

  test_nonSynthetic_unit_getter() async {
    var library = await buildLibrary(r'''
int get foo => 0;
''');
    configuration.withNonSynthetic = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @8
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
''');
  }

  test_nonSynthetic_unit_getterSetter() async {
    var library = await buildLibrary(r'''
int get foo => 0;
set foo(int value) {}
''');
    configuration.withNonSynthetic = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        get foo @8
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      setters
        set foo @22
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            value @30
              element: <testLibraryFragment>::@setter::foo::@parameter::value#element
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
      setter: <testLibraryFragment>::@setter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
      returnType: int
  setters
    static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional value
          type: int
      returnType: void
''');
  }

  test_nonSynthetic_unit_setter() async {
    var library = await buildLibrary(r'''
set foo(int value) {}
''');
    configuration.withNonSynthetic = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          setter2: <testLibraryFragment>::@setter::foo
      setters
        set foo @4
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            value @12
              element: <testLibraryFragment>::@setter::foo::@parameter::value#element
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      setter: <testLibraryFragment>::@setter::foo#element
  setters
    static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional value
          type: int
      returnType: void
''');
  }

  test_nonSynthetic_unit_variable() async {
    var library = await buildLibrary(r'''
int foo = 0;
''');
    configuration.withNonSynthetic = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
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
}

@reflectiveTest
class NonSyntheticElementTest_fromBytes extends NonSyntheticElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class NonSyntheticElementTest_keepLinking extends NonSyntheticElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
