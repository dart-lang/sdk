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
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 hasInitializer isOriginDeclaration foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::foo
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isCompleteDeclaration isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::foo
          setters
            #F5 isCompleteDeclaration isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer isOriginDeclaration shouldUseTypeForInitializerInference foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::foo
          setter: <testLibrary>::@class::C::@setter::foo
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        isOriginVariable foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo
      setters
        isOriginVariable foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo
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
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::foo
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isCompleteDeclaration isOriginDeclaration foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::C::@getter::foo
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        isOriginGetterSetter shouldUseTypeForInitializerInference foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::foo
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        isOriginDeclaration foo
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
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::foo
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 hasImplicitReturnType isCompleteDeclaration isOriginDeclaration foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::C::@setter::foo
              formalParameters
                #F5 requiredPositional isOriginDeclaration value (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        isOriginGetterSetter shouldUseTypeForInitializerInference foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::C::@setter::foo
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        isOriginDeclaration foo
          reference: <testLibrary>::@class::C::@setter::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::foo
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
        #F1 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic a (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic b (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::E::@field::b
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isCompleteDeclaration isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::a
            #F7 isCompleteDeclaration isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::b
            #F8 isCompleteDeclaration isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        isConst isOriginEnumValues isStatic shouldUseTypeForInitializerInference values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        isOriginVariable isStatic b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        isOriginVariable isStatic values
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
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          fields
            #F2 hasInitializer isOriginDeclaration foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@mixin::M::@field::foo
          getters
            #F3 isCompleteDeclaration isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::M::@getter::foo
          setters
            #F4 isCompleteDeclaration isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::M::@setter::foo
              formalParameters
                #F5 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@mixin::M::@setter::foo::@formalParameter::value
  mixins
    hasNonFinalField isSimplyBounded mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        hasInitializer isOriginDeclaration shouldUseTypeForInitializerInference foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@mixin::M::@getter::foo
          setter: <testLibrary>::@mixin::M::@setter::foo
      getters
        isOriginVariable foo
          reference: <testLibrary>::@mixin::M::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@mixin::M::@field::foo
      setters
        isOriginVariable foo
          reference: <testLibrary>::@mixin::M::@setter::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::M::@field::foo
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
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          fields
            #F2 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::M::@field::foo
          getters
            #F3 isCompleteDeclaration isOriginDeclaration foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@mixin::M::@getter::foo
  mixins
    isSimplyBounded mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        isOriginGetterSetter shouldUseTypeForInitializerInference foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@mixin::M::@getter::foo
      getters
        isOriginDeclaration foo
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
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          fields
            #F2 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::M::@field::foo
          setters
            #F3 hasImplicitReturnType isCompleteDeclaration isOriginDeclaration foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@mixin::M::@setter::foo
              formalParameters
                #F4 requiredPositional isOriginDeclaration value (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@mixin::M::@setter::foo::@formalParameter::value
  mixins
    isSimplyBounded mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        isOriginGetterSetter shouldUseTypeForInitializerInference foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@mixin::M::@setter::foo
      setters
        isOriginDeclaration foo
          reference: <testLibrary>::@mixin::M::@setter::foo
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F4
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::M::@field::foo
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
        #F1 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isCompleteDeclaration isOriginDeclaration isStatic foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::foo
  topLevelVariables
    isOriginGetterSetter isStatic shouldUseTypeForInitializerInference foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    isOriginDeclaration isStatic foo
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
        #F1 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isCompleteDeclaration isOriginDeclaration isStatic foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::foo
      setters
        #F3 hasImplicitReturnType isCompleteDeclaration isOriginDeclaration isStatic foo (nameOffset:22) (firstTokenOffset:18) (offset:22)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional isOriginDeclaration value (nameOffset:30) (firstTokenOffset:26) (offset:30)
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    isOriginGetterSetter isStatic shouldUseTypeForInitializerInference foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
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
        #F1 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
      setters
        #F2 hasImplicitReturnType isCompleteDeclaration isOriginDeclaration isStatic foo (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F3 requiredPositional isOriginDeclaration value (nameOffset:12) (firstTokenOffset:8) (offset:12)
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    isOriginGetterSetter isStatic shouldUseTypeForInitializerInference foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::foo
  setters
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F3
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
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
        #F1 hasInitializer isOriginDeclaration isStatic foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isCompleteDeclaration isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo
      setters
        #F3 isCompleteDeclaration isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration isStatic shouldUseTypeForInitializerInference foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
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
