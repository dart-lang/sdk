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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          fields
            #F2 hasInitializer foo @16
              element: <testLibrary>::@class::C::@field::foo
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic foo
              element: <testLibrary>::@class::C::@getter::foo
              returnType: int
          setters
            #F5 synthetic foo
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F6 _foo
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::_foo
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::foo
          setter: <testLibrary>::@class::C::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F5
          formalParameters
            requiredPositional _foo
              firstFragment: #F6
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          fields
            #F2 synthetic foo
              element: <testLibrary>::@class::C::@field::foo
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 foo @20
              element: <testLibrary>::@class::C::@getter::foo
              returnType: int
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          fields
            #F2 synthetic foo
              element: <testLibrary>::@class::C::@field::foo
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 foo @16
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F5 value @24
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::C::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F4
          formalParameters
            requiredPositional value
              firstFragment: #F5
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer a @11
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 hasInitializer b @14
              element: <testLibrary>::@enum::E::@field::b
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F4 synthetic values
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      element: <testLibrary>::@enum::E::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      element: <testLibrary>::@enum::E::@getter::b
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic a
              element: <testLibrary>::@enum::E::@getter::a
              returnType: E
            #F7 synthetic b
              element: <testLibrary>::@enum::E::@getter::b
              returnType: E
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        static const enumConstant hasInitializer b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        synthetic static a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        synthetic static b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M @6
          element: <testLibrary>::@mixin::M
          fields
            #F2 hasInitializer foo @16
              element: <testLibrary>::@mixin::M::@field::foo
          getters
            #F3 synthetic foo
              element: <testLibrary>::@mixin::M::@getter::foo
              returnType: int
          setters
            #F4 synthetic foo
              element: <testLibrary>::@mixin::M::@setter::foo
              formalParameters
                #F5 _foo
                  element: <testLibrary>::@mixin::M::@setter::foo::@formalParameter::_foo
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        hasInitializer foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@mixin::M::@getter::foo
          setter: <testLibrary>::@mixin::M::@setter::foo
      getters
        synthetic foo
          reference: <testLibrary>::@mixin::M::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@mixin::M::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@mixin::M::@setter::foo
          firstFragment: #F4
          formalParameters
            requiredPositional _foo
              firstFragment: #F5
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M @6
          element: <testLibrary>::@mixin::M
          fields
            #F2 synthetic foo
              element: <testLibrary>::@mixin::M::@field::foo
          getters
            #F3 foo @20
              element: <testLibrary>::@mixin::M::@getter::foo
              returnType: int
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@mixin::M::@getter::foo
      getters
        foo
          reference: <testLibrary>::@mixin::M::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@mixin::M::@field::foo
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M @6
          element: <testLibrary>::@mixin::M
          fields
            #F2 synthetic foo
              element: <testLibrary>::@mixin::M::@field::foo
          setters
            #F3 foo @16
              element: <testLibrary>::@mixin::M::@setter::foo
              formalParameters
                #F4 value @24
                  element: <testLibrary>::@mixin::M::@setter::foo::@formalParameter::value
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@mixin::M::@setter::foo
      setters
        foo
          reference: <testLibrary>::@mixin::M::@setter::foo
          firstFragment: #F3
          formalParameters
            requiredPositional value
              firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic foo (offset=-1)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 foo @8
          element: <testLibrary>::@getter::foo
          returnType: int
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic foo (offset=-1)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 foo @8
          element: <testLibrary>::@getter::foo
          returnType: int
      setters
        #F3 foo @22
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 value @30
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    static foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        requiredPositional value
          firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic foo (offset=-1)
          element: <testLibrary>::@topLevelVariable::foo
      setters
        #F2 foo @4
          element: <testLibrary>::@setter::foo
          formalParameters
            #F3 value @12
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::foo
  setters
    static foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F2
      formalParameters
        requiredPositional value
          firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer foo @4
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic foo
          element: <testLibrary>::@getter::foo
          returnType: int
      setters
        #F3 synthetic foo
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 _foo
              element: <testLibrary>::@setter::foo::@formalParameter::_foo
  topLevelVariables
    hasInitializer foo
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
    synthetic static foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        requiredPositional _foo
          firstFragment: #F4
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
