// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnonymousMethodElementTest_keepLinking);
    defineReflectiveTests(AnonymousMethodElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Tests that anonymous method invocations appearing in positions that get
/// serialized into summaries are replaced by the "not serializable" marker.
///
/// An anonymous method invocation can never be a constant expression (it
/// contains a function body, which the summary format has no representation
/// for), so the correct behavior is the same as for a function literal: the
/// expression is dropped and replaced by a marker. Without that replacement,
/// the expression reaches `AstBinaryWriter` and makes the whole library cycle
/// fail to link.
abstract class AnonymousMethodElementTest extends ElementsBaseTest {
  @override
  List<Feature> get experimentalFeatures => [
    ...super.experimentalFeatures,
    Feature.anonymous_methods,
  ];

  test_annotationArgument() async {
    var library = await buildLibrary(r'''
class A {
  const A(Object p);
}

@A(0.=> 1)
void f() {}
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
            #F2 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
              formalParameters
                #F3 requiredPositional isOriginDeclaration p (nameOffset:27) (firstTokenOffset:20) (offset:27)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::p
      functions
        #F4 isComplete isOriginDeclaration isStatic f (nameOffset:50) (firstTokenOffset:34) (offset:50)
          element: <testLibrary>::@function::f
          metadata
            Annotation
              atSign: @ @34
              name: SimpleIdentifier
                token: A @35
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @36
                arguments2
                  SimpleIdentifier
                    token: _notSerializableExpression @-1
                    element: <null>
                    staticType: null
                rightParenthesis: ) @43
              element: <testLibrary>::@class::A::@constructor::new
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional p
              firstFragment: #F3
              type: Object
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F4
      metadata
        Annotation
          atSign: @ @34
          name: SimpleIdentifier
            token: A @35
            element: <testLibrary>::@class::A
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @36
            arguments2
              SimpleIdentifier
                token: _notSerializableExpression @-1
                element: <null>
                staticType: null
            rightParenthesis: ) @43
          element: <testLibrary>::@class::A::@constructor::new
      returnType: void
''');
  }

  test_assertInitializer() async {
    var library = await buildLibrary(r'''
class A {
  const A() : assert(0.=> true);
}
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
            #F2 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:12) (offset:18)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 18
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          constantInitializers
            AssertInitializer
              assertKeyword: assert @24
              leftParenthesis: ( @30
              condition2: SimpleIdentifier
                token: _notSerializableExpression @-1
                element: <null>
                staticType: null
              rightParenthesis: ) @40
''');
  }

  test_constructorFieldInitializer() async {
    var library = await buildLibrary(r'''
class A {
  final Object f;
  const A() : f = 0.=> 1;
}
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
          fields
            #F2 isFinal isOriginDeclaration f (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::f
              inducedGetter: #F3
          constructors
            #F4 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:30) (offset:36)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 36
          getters
            #F3 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::f
              inducingVariable: #F2
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isFinal isOriginDeclaration f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F2
          type: Object
          getter: <testLibrary>::@class::A::@getter::f
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
          constantInitializers
            ConstructorFieldInitializer
              fieldName2: f @42
              fieldName(v1): SimpleIdentifier
                token: f @42
                element: <testLibrary>::@class::A::@field::f
                staticType: null
              equals: = @44
              expression2: SimpleIdentifier
                token: _notSerializableExpression @-1
                element: <null>
                staticType: null
              fieldElement: <testLibrary>::@class::A::@field::f
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F3
          returnType: Object
          variable: <testLibrary>::@class::A::@field::f
''');
  }

  test_constTopLevelVariable() async {
    var library = await buildLibrary(r'''
const v = 0.=> 1;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic v (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            SimpleIdentifier
              token: _notSerializableExpression @-1
              element: <null>
              staticType: null
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::v
          inducingVariable: #F1
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    isOriginVariable isStatic v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_defaultValue_constructor() async {
    var library = await buildLibrary(r'''
class A {
  A({Object p = 0.=> 1});
}
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
            #F2 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 optionalNamed isOriginDeclaration p (nameOffset:22) (firstTokenOffset:15) (offset:22)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::p
                  initializer: expression_0
                    SimpleIdentifier
                      token: _notSerializableExpression @-1
                      element: <null>
                      staticType: null
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 optionalNamed hasDefaultValue p
              firstFragment: #F3
              type: Object
              constantInitializer
                fragment: #F3
                expression: expression_0
''');
  }

  test_defaultValue_function() async {
    var library = await buildLibrary(r'''
void f({Object p = 0.=> 1}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 isComplete isOriginDeclaration isStatic f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 optionalNamed isOriginDeclaration p (nameOffset:15) (firstTokenOffset:8) (offset:15)
              element: <testLibrary>::@function::f::@formalParameter::p
              initializer: expression_0
                SimpleIdentifier
                  token: _notSerializableExpression @-1
                  element: <null>
                  staticType: null
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed hasDefaultValue p
          firstFragment: #F2
          type: Object
          constantInitializer
            fragment: #F2
            expression: expression_0
      returnType: void
''');
  }

  test_enumConstantArgument() async {
    var library = await buildLibrary(r'''
enum E {
  v(0.=> 1);

  const E(Object p);
}
''');
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                SimpleIdentifier
                  token: _notSerializableExpression @-1
                  element: <null>
                  staticType: null
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements2
                    UnqualifiedNameExpression
                      name: v @-1
                      resolution: GetterInvocationResolution
                        element: <testLibrary>::@enum::E::@getter::v
                        invokeType: E Function()
                        type: E
                      staticType: E
                  elements(v1)
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:25) (offset:31)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 31
              formalParameters
                #F7 requiredPositional isOriginDeclaration p (nameOffset:40) (firstTokenOffset:33) (offset:40)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::p
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional p
              firstFragment: #F7
              type: Object
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }
}

@reflectiveTest
class AnonymousMethodElementTest_fromBytes extends AnonymousMethodElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class AnonymousMethodElementTest_keepLinking
    extends AnonymousMethodElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
