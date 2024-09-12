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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            foo @16
              reference: <testLibraryFragment>::@class::C::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int
              shouldUseTypeForInitializerInference: true
              nonSynthetic: <testLibraryFragment>::@class::C::@field::foo
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              nonSynthetic: <testLibraryFragment>::@class::C
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::C::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
              nonSynthetic: <testLibraryFragment>::@class::C::@field::foo
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@class::C::@setter::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _foo @-1
                  type: int
                  nonSynthetic: <testLibraryFragment>::@class::C::@field::foo
              returnType: void
              nonSynthetic: <testLibraryFragment>::@class::C::@field::foo
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
            foo @16
              reference: <testLibraryFragment>::@class::C::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::foo
              setter2: <testLibraryFragment>::@class::C::@setter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::C::@getter::foo
              element: <none>
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@class::C::@setter::foo
              element: <none>
              parameters
                _foo @-1
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::foo
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::foo
      setters
        synthetic set foo=
          reference: <none>
          parameters
            requiredPositional _foo
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::C::@setter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@class::C::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int
              nonSynthetic: <testLibraryFragment>::@class::C::@getter::foo
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              nonSynthetic: <testLibraryFragment>::@class::C
          accessors
            get foo @20
              reference: <testLibraryFragment>::@class::C::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
              nonSynthetic: <testLibraryFragment>::@class::C::@getter::foo
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
            foo @-1
              reference: <testLibraryFragment>::@class::C::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get foo @20
              reference: <testLibraryFragment>::@class::C::@getter::foo
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        synthetic foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::foo
          getter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@class::C::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              type: int
              nonSynthetic: <testLibraryFragment>::@class::C::@setter::foo
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              nonSynthetic: <testLibraryFragment>::@class::C
          accessors
            set foo= @16
              reference: <testLibraryFragment>::@class::C::@setter::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional value @24
                  type: int
                  nonSynthetic: <testLibraryFragment>::@class::C::@setter::foo::@parameter::value
              returnType: void
              nonSynthetic: <testLibraryFragment>::@class::C::@setter::foo
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
            foo @-1
              reference: <testLibraryFragment>::@class::C::@field::foo
              element: <none>
              setter2: <testLibraryFragment>::@class::C::@setter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          setters
            set foo= @16
              reference: <testLibraryFragment>::@class::C::@setter::foo
              element: <none>
              parameters
                value @24
                  element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        synthetic foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@class::C::@field::foo
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      setters
        set foo=
          reference: <none>
          parameters
            requiredPositional value
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@class::C::@setter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @11
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              nonSynthetic: <testLibraryFragment>::@enum::E::@field::a
            static const enumConstant b @14
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              nonSynthetic: <testLibraryFragment>::@enum::E::@field::b
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              nonSynthetic: <testLibraryFragment>::@enum::E
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
              nonSynthetic: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
              nonSynthetic: <testLibraryFragment>::@enum::E::@field::a
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
              nonSynthetic: <testLibraryFragment>::@enum::E::@field::b
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
              nonSynthetic: <testLibraryFragment>::@enum::E
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant a @11
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            enumConstant b @14
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <none>
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          getter: <none>
        static const b
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            foo @16
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: int
              shouldUseTypeForInitializerInference: true
              nonSynthetic: <testLibraryFragment>::@mixin::M::@field::foo
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              returnType: int
              nonSynthetic: <testLibraryFragment>::@mixin::M::@field::foo
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::M::@setter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              parameters
                requiredPositional _foo @-1
                  type: int
                  nonSynthetic: <testLibraryFragment>::@mixin::M::@field::foo
              returnType: void
              nonSynthetic: <testLibraryFragment>::@mixin::M::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M
          fields
            foo @16
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@mixin::M::@getter::foo
              setter2: <testLibraryFragment>::@mixin::M::@setter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              element: <none>
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@mixin::M::@setter::foo
              element: <none>
              parameters
                _foo @-1
                  element: <none>
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          getter: <none>
          setter: <none>
      getters
        synthetic get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::foo
      setters
        synthetic set foo=
          reference: <none>
          parameters
            requiredPositional _foo
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@mixin::M::@setter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: int
              nonSynthetic: <testLibraryFragment>::@mixin::M::@getter::foo
          accessors
            get foo @20
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              returnType: int
              nonSynthetic: <testLibraryFragment>::@mixin::M::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M
          fields
            foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@mixin::M::@getter::foo
          getters
            get foo @20
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              element: <none>
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        synthetic foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          getter: <none>
      getters
        get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: int
              nonSynthetic: <testLibraryFragment>::@mixin::M::@setter::foo
          accessors
            set foo= @16
              reference: <testLibraryFragment>::@mixin::M::@setter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              parameters
                requiredPositional value @24
                  type: int
                  nonSynthetic: <testLibraryFragment>::@mixin::M::@setter::foo::@parameter::value
              returnType: void
              nonSynthetic: <testLibraryFragment>::@mixin::M::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M
          fields
            foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <none>
              setter2: <testLibraryFragment>::@mixin::M::@setter::foo
          setters
            set foo= @16
              reference: <testLibraryFragment>::@mixin::M::@setter::foo
              element: <none>
              parameters
                value @24
                  element: <none>
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        synthetic foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          setter: <none>
      setters
        set foo=
          reference: <none>
          parameters
            requiredPositional value
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@mixin::M::@setter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          nonSynthetic: <testLibraryFragment>::@getter::foo
      accessors
        static get foo @8
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
          nonSynthetic: <testLibraryFragment>::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @8
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  topLevelVariables
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          nonSynthetic: <testLibraryFragment>::@getter::foo
      accessors
        static get foo @8
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
          nonSynthetic: <testLibraryFragment>::@getter::foo
        static set foo= @22
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional value @30
              type: int
              nonSynthetic: <testLibraryFragment>::@setter::foo::@parameter::value
          returnType: void
          nonSynthetic: <testLibraryFragment>::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        get foo @8
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
      setters
        set foo= @22
          reference: <testLibraryFragment>::@setter::foo
          element: <none>
          parameters
            value @30
              element: <none>
  topLevelVariables
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
      setter: <none>
  getters
    static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    static set foo=
      reference: <none>
      parameters
        requiredPositional value
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          nonSynthetic: <testLibraryFragment>::@setter::foo
      accessors
        static set foo= @4
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional value @12
              type: int
              nonSynthetic: <testLibraryFragment>::@setter::foo::@parameter::value
          returnType: void
          nonSynthetic: <testLibraryFragment>::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          setter2: <testLibraryFragment>::@setter::foo
      setters
        set foo= @4
          reference: <testLibraryFragment>::@setter::foo
          element: <none>
          parameters
            value @12
              element: <none>
  topLevelVariables
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      setter: <none>
  setters
    static set foo=
      reference: <none>
      parameters
        requiredPositional value
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          nonSynthetic: <testLibraryFragment>::@topLevelVariable::foo
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
          nonSynthetic: <testLibraryFragment>::@topLevelVariable::foo
        synthetic static set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _foo @-1
              type: int
              nonSynthetic: <testLibraryFragment>::@topLevelVariable::foo
          returnType: void
          nonSynthetic: <testLibraryFragment>::@topLevelVariable::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        foo @4
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
      setters
        set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          element: <none>
          parameters
            _foo @-1
              element: <none>
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
