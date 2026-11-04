// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../element_text.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MetadataElementTest_keepLinking);
    defineReflectiveTests(MetadataElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class MetadataElementTest extends ElementsBaseTest {
  test_annotationArgument_forElement() async {
    var library = await buildLibrary(r'''
class A {
  const A(Object? o);
}

@A([for (var i in []) i])
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
                #F3 requiredPositional isOriginDeclaration o (nameOffset:28) (firstTokenOffset:20) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::o
      functions
        #F4 isComplete isOriginDeclaration isStatic f (nameOffset:66) (firstTokenOffset:35) (offset:66)
          element: <testLibrary>::@function::f
          metadata
            annotation_0: Annotation
              atSign: @ @35
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @36
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @37
                  arguments2
                    UnqualifiedNameExpression
                      name: _notSerializableExpression @-1
                      resolution: <null>
                      staticType: null
                  arguments(v1)
                    SimpleIdentifier
                      token: _notSerializableExpression @-1
                      element: <null>
                      staticType: null
                  rightParenthesis: ) @59
                staticType: A
              name: SimpleIdentifier
                token: A @36
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @37
                arguments
                  SimpleIdentifier
                    token: _notSerializableExpression @-1
                    element: <null>
                    staticType: null
                rightParenthesis: ) @59
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
            #E0 requiredPositional o
              firstFragment: #F3
              type: Object?
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F4
      metadata
        annotation_0
      returnType: void
''');
  }

  test_annotationArgument_functionExpression() async {
    var library = await buildLibrary(r'''
class A {
  const A(Object? o);
}

@A(() {})
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
                #F3 requiredPositional isOriginDeclaration o (nameOffset:28) (firstTokenOffset:20) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::o
      functions
        #F4 isComplete isOriginDeclaration isStatic f (nameOffset:50) (firstTokenOffset:35) (offset:50)
          element: <testLibrary>::@function::f
          metadata
            annotation_0: Annotation
              atSign: @ @35
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @36
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @37
                  arguments2
                    UnqualifiedNameExpression
                      name: _notSerializableExpression @-1
                      resolution: <null>
                      staticType: null
                  arguments(v1)
                    SimpleIdentifier
                      token: _notSerializableExpression @-1
                      element: <null>
                      staticType: null
                  rightParenthesis: ) @43
                staticType: A
              name: SimpleIdentifier
                token: A @36
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @37
                arguments
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
            #E0 requiredPositional o
              firstFragment: #F3
              type: Object?
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F4
      metadata
        annotation_0
      returnType: void
''');
  }

  test_annotationArgument_functionExpression_functionTypeFormalParameter() async {
    var library = await buildLibrary(r'''
class A {
  const A(Object? o);
}

void f(void Function(@A(() {}) int x) g) {}
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
                #F3 requiredPositional isOriginDeclaration o (nameOffset:28) (firstTokenOffset:20) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::o
      functions
        #F4 isComplete isOriginDeclaration isStatic f (nameOffset:40) (firstTokenOffset:35) (offset:40)
          element: <testLibrary>::@function::f
          formalParameters
            #F5 requiredPositional isOriginDeclaration g (nameOffset:73) (firstTokenOffset:42) (offset:73)
              element: <testLibrary>::@function::f::@formalParameter::g
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional o
              firstFragment: #F3
              type: Object?
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F4
      formalParameters
        #E1 requiredPositional g
          firstFragment: #F5
          type: void Function(int)
      returnType: void
''');
  }

  test_annotationArgument_functionExpression_nextArgument() async {
    var library = await buildLibrary(r'''
class A {
  const A(Object? a, Object? b);
}

@A(() {}, 1)
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
                #F3 requiredPositional isOriginDeclaration a (nameOffset:28) (firstTokenOffset:20) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                #F4 requiredPositional isOriginDeclaration b (nameOffset:39) (firstTokenOffset:31) (offset:39)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::b
      functions
        #F5 isComplete isOriginDeclaration isStatic f (nameOffset:64) (firstTokenOffset:46) (offset:64)
          element: <testLibrary>::@function::f
          metadata
            annotation_0: Annotation
              atSign: @ @46
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @47
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @48
                  arguments2
                    UnqualifiedNameExpression
                      name: _notSerializableExpression @-1
                      resolution: <null>
                      staticType: null
                    IntegerLiteral
                      literal: 1 @56
                      staticType: int
                  arguments(v1)
                    SimpleIdentifier
                      token: _notSerializableExpression @-1
                      element: <null>
                      staticType: null
                    IntegerLiteral
                      literal: 1 @56
                      staticType: int
                  rightParenthesis: ) @57
                staticType: A
              name: SimpleIdentifier
                token: A @47
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @48
                arguments
                  SimpleIdentifier
                    token: _notSerializableExpression @-1
                    element: <null>
                    staticType: null
                  IntegerLiteral
                    literal: 1 @56
                    staticType: int
                rightParenthesis: ) @57
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
            #E0 requiredPositional a
              firstFragment: #F3
              type: Object?
            #E1 requiredPositional b
              firstFragment: #F4
              type: Object?
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F5
      metadata
        annotation_0
      returnType: void
''');
  }

  test_annotationArgument_functionExpression_nextNamedArgument() async {
    var library = await buildLibrary(r'''
class A {
  const A({Object? a, Object? b});
}

@A(a: () {}, b: 1)
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
                #F3 optionalNamed isOriginDeclaration a (nameOffset:29) (firstTokenOffset:21) (offset:29)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                #F4 optionalNamed isOriginDeclaration b (nameOffset:40) (firstTokenOffset:32) (offset:40)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::b
      functions
        #F5 isComplete isOriginDeclaration isStatic f (nameOffset:72) (firstTokenOffset:48) (offset:72)
          element: <testLibrary>::@function::f
          metadata
            annotation_0: Annotation
              atSign: @ @48
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @49
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @50
                  arguments2
                    NamedArgument
                      name: a @51
                      colon: : @52
                      argumentExpression2: UnqualifiedNameExpression
                        name: _notSerializableExpression @-1
                        resolution: <null>
                        staticType: null
                      argumentExpression(v1): SimpleIdentifier
                        token: _notSerializableExpression @-1
                        element: <null>
                        staticType: null
                    NamedArgument
                      name: b @61
                      colon: : @62
                      argumentExpression2: IntegerLiteral
                        literal: 1 @64
                        staticType: int
                  rightParenthesis: ) @65
                staticType: A
              name: SimpleIdentifier
                token: A @49
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @50
                arguments
                  NamedArgument
                    name: a @51
                    colon: : @52
                    argumentExpression: SimpleIdentifier
                      token: _notSerializableExpression @-1
                      element: <null>
                      staticType: null
                  NamedArgument
                    name: b @61
                    colon: : @62
                    argumentExpression: IntegerLiteral
                      literal: 1 @64
                      staticType: int
                rightParenthesis: ) @65
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
            #E0 optionalNamed a
              firstFragment: #F3
              type: Object?
            #E1 optionalNamed b
              firstFragment: #F4
              type: Object?
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F5
      metadata
        annotation_0
      returnType: void
''');
  }

  test_annotationArgument_functionExpression_typeParameter_ofClass() async {
    var library = await buildLibrary(r'''
class A {
  const A(Object? o);
}

class B<@A(() {}) T> {}
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
                #F3 requiredPositional isOriginDeclaration o (nameOffset:28) (firstTokenOffset:20) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::o
        #F4 class B (nameOffset:41) (firstTokenOffset:35) (offset:41)
          element: <testLibrary>::@class::B
          typeParameters
            #F5 T (nameOffset:53) (firstTokenOffset:43) (offset:53)
              element: #E0 T
              metadata
                annotation_0: Annotation
                  atSign: @ @43
                  expression: ConstructorInvocation
                    constructorReference: ConstructorReference2
                      typeReference: ConstructorTypeReference
                        name: A @44
                        element: <testLibrary>::@class::A
                        type: A
                      element: <testLibrary>::@class::A::@constructor::new
                    argumentList: ArgumentList
                      leftParenthesis: ( @45
                      arguments2
                        UnqualifiedNameExpression
                          name: _notSerializableExpression @-1
                          resolution: <null>
                          staticType: null
                      arguments(v1)
                        SimpleIdentifier
                          token: _notSerializableExpression @-1
                          element: <null>
                          staticType: null
                      rightParenthesis: ) @51
                    staticType: A
                  name: SimpleIdentifier
                    token: A @44
                    element: <testLibrary>::@class::A
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @45
                    arguments
                      SimpleIdentifier
                        token: _notSerializableExpression @-1
                        element: <null>
                        staticType: null
                    rightParenthesis: ) @51
                  element: <testLibrary>::@class::A::@constructor::new
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E1 requiredPositional o
              firstFragment: #F3
              type: Object?
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      typeParameters
        #E0 T
          firstFragment: #F5
          metadata
            annotation_0
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
''');
  }

  test_annotationArgument_functionExpression_typeParameter_ofTypeAlias() async {
    var library = await buildLibrary(r'''
class A {
  const A(Object? o);
}

typedef F<@A(() {}) T> = void Function();
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
                #F3 requiredPositional isOriginDeclaration o (nameOffset:28) (firstTokenOffset:20) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::o
      typeAliases
        #F4 F (nameOffset:43) (firstTokenOffset:35) (offset:43)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F5 T (nameOffset:55) (firstTokenOffset:45) (offset:55)
              element: #E0 T
              metadata
                annotation_0: Annotation
                  atSign: @ @45
                  expression: ConstructorInvocation
                    constructorReference: ConstructorReference2
                      typeReference: ConstructorTypeReference
                        name: A @46
                        element: <testLibrary>::@class::A
                        type: A
                      element: <testLibrary>::@class::A::@constructor::new
                    argumentList: ArgumentList
                      leftParenthesis: ( @47
                      arguments2
                        UnqualifiedNameExpression
                          name: _notSerializableExpression @-1
                          resolution: <null>
                          staticType: null
                      arguments(v1)
                        SimpleIdentifier
                          token: _notSerializableExpression @-1
                          element: <null>
                          staticType: null
                      rightParenthesis: ) @53
                    staticType: A
                  name: SimpleIdentifier
                    token: A @46
                    element: <testLibrary>::@class::A
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @47
                    arguments
                      SimpleIdentifier
                        token: _notSerializableExpression @-1
                        element: <null>
                        staticType: null
                    rightParenthesis: ) @53
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
            #E1 requiredPositional o
              firstFragment: #F3
              type: Object?
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      typeParameters
        #E0 T
          firstFragment: #F5
          metadata
            annotation_0
      aliasedType: void Function()
''');
  }

  test_annotationArgument_recordLiteral() async {
    var library = await buildLibrary(r'''
@A((2, a: 3))
class C {}

class A {
  const A(o);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:20) (firstTokenOffset:0) (offset:20)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @0
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @1
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @2
                  arguments2
                    RecordLiteral
                      leftParenthesis: ( @3
                      fields2
                        IntegerLiteral
                          literal: 2 @4
                          staticType: int
                        RecordLiteralNamedField
                          name: a @7
                          colon: : @8
                          fieldExpression2: IntegerLiteral
                            literal: 3 @10
                            staticType: int
                      rightParenthesis: ) @11
                      staticType: (int, {int a})
                  rightParenthesis: ) @12
                staticType: A
              name: SimpleIdentifier
                token: A @1
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @2
                arguments
                  RecordLiteral
                    leftParenthesis: ( @3
                    fields
                      IntegerLiteral
                        literal: 2 @4
                        staticType: int
                      RecordLiteralNamedField
                        name: a @7
                        colon: : @8
                        fieldExpression: IntegerLiteral
                          literal: 3 @10
                          staticType: int
                    rightParenthesis: ) @11
                    staticType: (int, {int a})
                rightParenthesis: ) @12
              element: <testLibrary>::@class::A::@constructor::new
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class A (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::A
          constructors
            #F4 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:38) (offset:44)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 44
              formalParameters
                #F5 requiredPositional hasImplicitType isOriginDeclaration o (nameOffset:46) (firstTokenOffset:46) (offset:46)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::o
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType o
              firstFragment: #F5
              type: dynamic
''');
  }

  test_annotationArgument_recordLiteral_withConst() async {
    var library = await buildLibrary(r'''
@A(const ('',))
class C {}

class A {
  const A(o);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:0) (offset:22)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @0
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @1
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @2
                  arguments2
                    RecordLiteral
                      constKeyword: const @3
                      leftParenthesis: ( @9
                      fields2
                        SimpleStringLiteral
                          literal: '' @10
                      rightParenthesis: ) @13
                      staticType: (String,)
                  rightParenthesis: ) @14
                staticType: A
              name: SimpleIdentifier
                token: A @1
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @2
                arguments
                  RecordLiteral
                    constKeyword: const @3
                    leftParenthesis: ( @9
                    fields
                      SimpleStringLiteral
                        literal: '' @10
                    rightParenthesis: ) @13
                    staticType: (String,)
                rightParenthesis: ) @14
              element: <testLibrary>::@class::A::@constructor::new
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class A (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::A
          constructors
            #F4 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:40) (offset:46)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 46
              formalParameters
                #F5 requiredPositional hasImplicitType isOriginDeclaration o (nameOffset:48) (firstTokenOffset:48) (offset:48)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::o
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType o
              firstFragment: #F5
              type: dynamic
''');
  }

  test_annotationArgument_switchExpression_nextArgument() async {
    var library = await buildLibrary(r'''
class A {
  const A(Object? a, Object? b);
}

@A(switch (0) { _ => 0 }, 1)
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
                #F3 requiredPositional isOriginDeclaration a (nameOffset:28) (firstTokenOffset:20) (offset:28)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                #F4 requiredPositional isOriginDeclaration b (nameOffset:39) (firstTokenOffset:31) (offset:39)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::b
      functions
        #F5 isComplete isOriginDeclaration isStatic f (nameOffset:80) (firstTokenOffset:46) (offset:80)
          element: <testLibrary>::@function::f
          metadata
            annotation_0: Annotation
              atSign: @ @46
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @47
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @48
                  arguments2
                    UnqualifiedNameExpression
                      name: _notSerializableExpression @-1
                      resolution: <null>
                      staticType: null
                    IntegerLiteral
                      literal: 1 @72
                      staticType: int
                  arguments(v1)
                    SimpleIdentifier
                      token: _notSerializableExpression @-1
                      element: <null>
                      staticType: null
                    IntegerLiteral
                      literal: 1 @72
                      staticType: int
                  rightParenthesis: ) @73
                staticType: A
              name: SimpleIdentifier
                token: A @47
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @48
                arguments
                  SimpleIdentifier
                    token: _notSerializableExpression @-1
                    element: <null>
                    staticType: null
                  IntegerLiteral
                    literal: 1 @72
                    staticType: int
                rightParenthesis: ) @73
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
            #E0 requiredPositional a
              firstFragment: #F3
              type: Object?
            #E1 requiredPositional b
              firstFragment: #F4
              type: Object?
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F5
      metadata
        annotation_0
      returnType: void
''');
  }

  test_invalid_annotation_prefixed_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named();
}
''');
    var library = await buildLibrary(r'''
import "a.dart" as a;

@a.A.named
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as a (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix::a
          fragments: @19
      classes
        #F1 class C (nameOffset:40) (firstTokenOffset:23) (offset:40)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @23
              expression: ConstructorTearOff
                typeReference: ConstructorTypeReference
                  importPrefix: ImportPrefixReference
                    name: a @24
                    period: . @25
                    element: <testLibraryFragment>::@prefix::a
                  name: A @26
                  element: package:test/a.dart::@class::A
                  type: A
                selector: ConstructorSelector
                  period: . @27
                  name2: named @28
                element: package:test/a.dart::@class::A::@constructor::named
                staticType: A Function()
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: a @24
                  element: <testLibraryFragment>::@prefix::a
                  staticType: null
                period: . @25
                identifier: SimpleIdentifier
                  token: A @26
                  element: package:test/a.dart::@class::A
                  staticType: null
                element: package:test/a.dart::@class::A
                staticType: null
              period: . @27
              constructorName: SimpleIdentifier
                token: named @28
                element: package:test/a.dart::@class::A::@constructor::named
                staticType: null
              element: package:test/a.dart::@class::A::@constructor::named
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_invalid_annotation_unprefixed_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named();
}
''');
    var library = await buildLibrary(r'''
import "a.dart";

@A.named
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      classes
        #F1 class C (nameOffset:33) (firstTokenOffset:18) (offset:33)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @18
              expression: ConstructorTearOff
                typeReference: ConstructorTypeReference
                  name: A @19
                  element: package:test/a.dart::@class::A
                  type: A
                selector: ConstructorSelector
                  period: . @20
                  name2: named @21
                element: package:test/a.dart::@class::A::@constructor::named
                staticType: A Function()
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: A @19
                  element: package:test/a.dart::@class::A
                  staticType: null
                period: . @20
                identifier: SimpleIdentifier
                  token: named @21
                  element: package:test/a.dart::@class::A::@constructor::named
                  staticType: null
                element: package:test/a.dart::@class::A::@constructor::named
                staticType: null
              element: package:test/a.dart::@class::A::@constructor::named
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_metadata_class_field_declaringFormalParameter_first() async {
    var library = await buildLibrary(r'''
const a = 0;

class A(@a final int foo);
''');
    // Check metadata without asking any other properties.
    var foo = library.getClass('A')!.getField('foo')!;
    configuration.withCombinedFragmentData(foo, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@class::A::@field::foo
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @22
        expression: UnqualifiedNameExpression
          name: a @23
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @23
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
  fragments
    #F0
library
  reference: <testLibrary>
  fragments
    #F1 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F2 class A (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::A
          fields
            #F0 isFinal isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::A::@field::foo
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:20) (offset:20)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 20
              primaryHeaderCodeRange: 21 + 18
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.foo (nameOffset:35) (firstTokenOffset:22) (offset:35)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::foo
                  metadata
                    annotation_1: Annotation
                      atSign: @ @22
                      expression: UnqualifiedNameExpression
                        name: a @23
                        resolution: GetterInvocationResolution
                          element: <testLibrary>::@getter::a
                          type: int
                        staticType: int
                      name: SimpleIdentifier
                        token: a @23
                        element: <testLibrary>::@getter::a
                        staticType: null
                      element: <testLibrary>::@getter::a
          getters
            #F3 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
              inducingVariable: #F0
      topLevelVariables
        #F6 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F7
      getters
        #F7 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F6
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F2
      fields
        isFinal isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F0
          metadata
            annotation_0
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          declaringFormalParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::foo
      constructors
        isOriginDeclaration isPrimary new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.foo
              firstFragment: #F5
              type: int
              metadata
                annotation_1
              field: <testLibrary>::@class::A::@field::foo
      getters
        isOriginVariable foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F6
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_class_field_first() async {
    var library = await buildLibrary(r'''
const a = 0;

class C {
  @a
  int x = 0;
}
''');
    // Check metadata without asking any other properties.
    var x = library.getClass('C')!.getField('x')!;
    expect(x.metadata.annotations, hasLength(1));
    // Check details.
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::C
          fields
            #F2 hasInitializer isOriginDeclaration x (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: <testLibrary>::@class::C::@field::x
              metadata
                annotation_0: Annotation
                  atSign: @ @26
                  expression: UnqualifiedNameExpression
                    name: a @27
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: a @27
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@class::C::@getter::x
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@class::C::@setter::x
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F8
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
  classes
    hasNonFinalField isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer isOriginDeclaration x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          metadata
            annotation_0
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_class_scope() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
class C<@foo T> {
  static const foo = 1;
  @foo
  void bar() {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:27) (firstTokenOffset:16) (offset:27)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: foo @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          typeParameters
            #F2 T (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: #E0 T
              metadata
                annotation_1: Annotation
                  atSign: @ @29
                  expression: UnqualifiedNameExpression
                    name: foo @30
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @30
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
          fields
            #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:54) (firstTokenOffset:54) (offset:54)
              element: <testLibrary>::@class::C::@field::foo
              constantInitializer2: expression_0
                IntegerLiteral
                  literal: 1 @60
                  staticType: int
              inducedGetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::C::@getter::foo
              inducingVariable: #F3
          methods
            #F6 isComplete isOriginDeclaration bar (nameOffset:77) (firstTokenOffset:65) (offset:77)
              element: <testLibrary>::@class::C::@method::bar
              metadata
                annotation_2: Annotation
                  atSign: @ @65
                  expression: UnqualifiedNameExpression
                    name: foo @66
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@class::C::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @66
                    element: <testLibrary>::@class::C::@getter::foo
                    staticType: null
                  element: <testLibrary>::@class::C::@getter::foo
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F8
      getters
        #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F7
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            annotation_1
      fields
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
          reference: <testLibrary>::@class::C::@field::foo
          firstFragment: #F3
          type: int
          constantInitializer2: expression_0
          getter: <testLibrary>::@class::C::@getter::foo
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        isOriginVariable isStatic foo
          reference: <testLibrary>::@class::C::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::foo
      methods
        isOriginDeclaration bar
          reference: <testLibrary>::@class::C::@method::bar
          firstFragment: #F6
          metadata
            annotation_2
          returnType: void
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F7
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_classDeclaration() async {
    var library = await buildLibrary(r'''
const a = null;
const b = null;

@a
@b
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:45) (firstTokenOffset:33) (offset:45)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @33
              expression: UnqualifiedNameExpression
                name: a @34
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: a @34
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
            annotation_1: Annotation
              atSign: @ @36
              expression: UnqualifiedNameExpression
                name: b @37
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::b
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: b @37
                element: <testLibrary>::@getter::b
                staticType: null
              element: <testLibrary>::@getter::b
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F4
        #F5 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
          inducedGetter: #F6
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
        #F6 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::b
          inducingVariable: #F5
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
        annotation_1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F5
      type: dynamic
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_classDeclaration_augmentation_inBoth_first() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = 0;

@a
class A {}

@b
augment class A {}
''');
    // Check metadata without asking any other properties.
    var A = library.getClass('A')!;
    configuration.withCombinedFragmentData(A, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@class::A
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @27
        expression: UnqualifiedNameExpression
          name: a @28
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @28
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
      annotation_1: Annotation
        atSign: @ @42
        expression: UnqualifiedNameExpression
          name: b @43
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::b
            type: int
          staticType: int
        name: SimpleIdentifier
          token: b @43
          element: <testLibrary>::@getter::b
          staticType: null
        element: <testLibrary>::@getter::b
  fragments
    #F0
      metadata
        annotation_0
    #F1
      metadata
        annotation_1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F0 class A (nameOffset:36) (firstTokenOffset:27) (offset:36)
          element: <testLibrary>::@class::A
          metadata
            annotation_0
          nextFragment: #F1
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F1 isAugmentation class A (nameOffset:59) (firstTokenOffset:42) (offset:59)
          element: <testLibrary>::@class::A
          metadata
            annotation_1
          previousFragment: #F0
      topLevelVariables
        #F4 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F5
        #F6 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 0 @23
              staticType: int
          inducedGetter: #F7
      getters
        #F5 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F4
        #F7 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F6
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F0
      metadata
        annotation_0
        annotation_1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F6
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_classTypeAlias() async {
    var library = await buildLibrary(r'''
const a = null;
@a
class C = D with E;

class D {}

class E {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 isMixinApplication class C (nameOffset:25) (firstTokenOffset:16) (offset:25)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: a @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: a @17
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          constructors
            #F2 isOriginMixinApplication new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:46) (firstTokenOffset:40) (offset:46)
          element: <testLibrary>::@class::D
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F5 class E (nameOffset:58) (firstTokenOffset:52) (offset:58)
          element: <testLibrary>::@class::E
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F8
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
  classes
    isMixinApplication isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      supertype: D
      mixins
        E
      constructors
        isOriginMixinApplication new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::D::@constructor::new
          superConstructor: <testLibrary>::@class::D::@constructor::new
    isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
    isSimplyBounded class E
      reference: <testLibrary>::@class::E
      firstFragment: #F5
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F6
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_constructor_call_named() async {
    var library = await buildLibrary(r'''
class A {
  const A.named(int _);
}

@A.named(0)
class C {}
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
            #F2 isConst isOriginDeclaration named (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 18
              periodOffset: 19
              formalParameters
                #F3 requiredPositional isOriginDeclaration _ (nameOffset:30) (firstTokenOffset:26) (offset:30)
                  element: <testLibrary>::@class::A::@constructor::named::@formalParameter::_
        #F4 class C (nameOffset:55) (firstTokenOffset:37) (offset:55)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @37
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @38
                    element: <testLibrary>::@class::A
                    type: A
                  selector: ConstructorSelector
                    period: . @39
                    name2: named @40
                  element: <testLibrary>::@class::A::@constructor::named
                argumentList: ArgumentList
                  leftParenthesis: ( @45
                  arguments2
                    IntegerLiteral
                      literal: 0 @46
                      staticType: int
                  rightParenthesis: ) @47
                staticType: A
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: A @38
                  element: <testLibrary>::@class::A
                  staticType: null
                period: . @39
                identifier: SimpleIdentifier
                  token: named @40
                  element: <testLibrary>::@class::A::@constructor::named
                  staticType: null
                element: <testLibrary>::@class::A::@constructor::named
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @45
                arguments
                  IntegerLiteral
                    literal: 0 @46
                    staticType: int
                rightParenthesis: ) @47
              element: <testLibrary>::@class::A::@constructor::named
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isConst isOriginDeclaration named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F3
              type: int
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_metadata_constructor_call_named_generic_inference() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A.named(T _);
}

@A.named(0)
class C {}
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
            #F3 isConst isOriginDeclaration named (nameOffset:23) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 21
              periodOffset: 22
              formalParameters
                #F4 requiredPositional isOriginDeclaration _ (nameOffset:31) (firstTokenOffset:29) (offset:31)
                  element: <testLibrary>::@class::A::@constructor::named::@formalParameter::_
        #F5 class C (nameOffset:56) (firstTokenOffset:38) (offset:56)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @38
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @39
                    element: <testLibrary>::@class::A
                    type: A<int>
                  selector: ConstructorSelector
                    period: . @40
                    name2: named @41
                  element: SubstitutedConstructorElementImpl
                    baseElement: <testLibrary>::@class::A::@constructor::named
                    substitution: {T: int}
                argumentList: ArgumentList
                  leftParenthesis: ( @46
                  arguments2
                    IntegerLiteral
                      literal: 0 @47
                      staticType: int
                  rightParenthesis: ) @48
                staticType: A<int>
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: A @39
                  element: <testLibrary>::@class::A
                  staticType: null
                period: . @40
                identifier: SimpleIdentifier
                  token: named @41
                  element: SubstitutedConstructorElementImpl
                    baseElement: <testLibrary>::@class::A::@constructor::named
                    substitution: {T: int}
                  staticType: null
                element: SubstitutedConstructorElementImpl
                  baseElement: <testLibrary>::@class::A::@constructor::named
                  substitution: {T: int}
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @46
                arguments
                  IntegerLiteral
                    literal: 0 @47
                    staticType: int
                rightParenthesis: ) @48
              element: SubstitutedConstructorElementImpl
                baseElement: <testLibrary>::@class::A::@constructor::named
                substitution: {T: int}
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F4
              type: T
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
''');
  }

  test_metadata_constructor_call_named_generic_typeArguments() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A.named();
}

@A<int>.named()
class C {}
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
            #F3 isConst isOriginDeclaration named (nameOffset:23) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 21
              periodOffset: 22
        #F4 class C (nameOffset:57) (firstTokenOffset:35) (offset:57)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @35
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @36
                    typeArguments: TypeArgumentList
                      leftBracket: < @37
                      arguments
                        NamedType
                          name: int @38
                          element: dart:core::@class::int
                          type: int
                      rightBracket: > @41
                    element: <testLibrary>::@class::A
                    type: A<int>
                  selector: ConstructorSelector
                    period: . @42
                    name2: named @43
                  element: SubstitutedConstructorElementImpl
                    baseElement: <testLibrary>::@class::A::@constructor::named
                    substitution: {T: int}
                argumentList: ArgumentList
                  leftParenthesis: ( @48
                  rightParenthesis: ) @49
                staticType: A<int>
              name: SimpleIdentifier
                token: A @36
                element: <testLibrary>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @37
                arguments
                  NamedType
                    name: int @38
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @41
              period: . @42
              constructorName: SimpleIdentifier
                token: named @43
                element: SubstitutedConstructorElementImpl
                  baseElement: <testLibrary>::@class::A::@constructor::named
                  substitution: {T: int}
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @48
                rightParenthesis: ) @49
              element: SubstitutedConstructorElementImpl
                baseElement: <testLibrary>::@class::A::@constructor::named
                substitution: {T: int}
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_metadata_constructor_call_named_generic_typeArguments_disabledGenericMetadata() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A.named();
}

@A<int>.named()
class C {}
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
            #F3 isConst isOriginDeclaration named (nameOffset:23) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 21
              periodOffset: 22
        #F4 class C (nameOffset:57) (firstTokenOffset:35) (offset:57)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @35
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @36
                    typeArguments: TypeArgumentList
                      leftBracket: < @37
                      arguments
                        NamedType
                          name: int @38
                          element: dart:core::@class::int
                          type: int
                      rightBracket: > @41
                    element: <testLibrary>::@class::A
                    type: A<int>
                  selector: ConstructorSelector
                    period: . @42
                    name2: named @43
                  element: SubstitutedConstructorElementImpl
                    baseElement: <testLibrary>::@class::A::@constructor::named
                    substitution: {T: int}
                argumentList: ArgumentList
                  leftParenthesis: ( @48
                  rightParenthesis: ) @49
                staticType: A<int>
              name: SimpleIdentifier
                token: A @36
                element: <testLibrary>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @37
                arguments
                  NamedType
                    name: int @38
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @41
              period: . @42
              constructorName: SimpleIdentifier
                token: named @43
                element: SubstitutedConstructorElementImpl
                  baseElement: <testLibrary>::@class::A::@constructor::named
                  substitution: {T: int}
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @48
                rightParenthesis: ) @49
              element: SubstitutedConstructorElementImpl
                baseElement: <testLibrary>::@class::A::@constructor::named
                substitution: {T: int}
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_metadata_constructor_call_named_prefixed() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  const A.named(int _);
}
''');
    var library = await buildLibrary(r'''
import 'foo.dart' as foo;

@foo.A.named(0)
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix::foo
          fragments: @21
      classes
        #F1 class C (nameOffset:49) (firstTokenOffset:27) (offset:49)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @27
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    importPrefix: ImportPrefixReference
                      name: foo @28
                      period: . @31
                      element: <testLibraryFragment>::@prefix::foo
                    name: A @32
                    element: package:test/foo.dart::@class::A
                    type: A
                  selector: ConstructorSelector
                    period: . @33
                    name2: named @34
                  element: package:test/foo.dart::@class::A::@constructor::named
                argumentList: ArgumentList
                  leftParenthesis: ( @39
                  arguments2
                    IntegerLiteral
                      literal: 0 @40
                      staticType: int
                  rightParenthesis: ) @41
                staticType: A
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @28
                  element: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @31
                identifier: SimpleIdentifier
                  token: A @32
                  element: package:test/foo.dart::@class::A
                  staticType: null
                element: package:test/foo.dart::@class::A
                staticType: null
              period: . @33
              constructorName: SimpleIdentifier
                token: named @34
                element: package:test/foo.dart::@class::A::@constructor::named
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @39
                arguments
                  IntegerLiteral
                    literal: 0 @40
                    staticType: int
                rightParenthesis: ) @41
              element: package:test/foo.dart::@class::A::@constructor::named
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_metadata_constructor_call_named_prefixed_generic_inference() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A<T> {
  const A.named(T _);
}
''');
    var library = await buildLibrary(r'''
import "foo.dart" as foo;

@foo.A.named(0)
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix::foo
          fragments: @21
      classes
        #F1 class C (nameOffset:49) (firstTokenOffset:27) (offset:49)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @27
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    importPrefix: ImportPrefixReference
                      name: foo @28
                      period: . @31
                      element: <testLibraryFragment>::@prefix::foo
                    name: A @32
                    element: package:test/foo.dart::@class::A
                    type: A<int>
                  selector: ConstructorSelector
                    period: . @33
                    name2: named @34
                  element: SubstitutedConstructorElementImpl
                    baseElement: package:test/foo.dart::@class::A::@constructor::named
                    substitution: {T: int}
                argumentList: ArgumentList
                  leftParenthesis: ( @39
                  arguments2
                    IntegerLiteral
                      literal: 0 @40
                      staticType: int
                  rightParenthesis: ) @41
                staticType: A<int>
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @28
                  element: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @31
                identifier: SimpleIdentifier
                  token: A @32
                  element: package:test/foo.dart::@class::A
                  staticType: null
                element: package:test/foo.dart::@class::A
                staticType: null
              period: . @33
              constructorName: SimpleIdentifier
                token: named @34
                element: SubstitutedConstructorElementImpl
                  baseElement: package:test/foo.dart::@class::A::@constructor::named
                  substitution: {T: int}
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @39
                arguments
                  IntegerLiteral
                    literal: 0 @40
                    staticType: int
                rightParenthesis: ) @41
              element: SubstitutedConstructorElementImpl
                baseElement: package:test/foo.dart::@class::A::@constructor::named
                substitution: {T: int}
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_metadata_constructor_call_named_prefixed_generic_typeArguments() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A<T> {
  const A.named();
}
''');
    var library = await buildLibrary(r'''
import "foo.dart" as foo;

@foo.A<int>.named()
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix::foo
          fragments: @21
      classes
        #F1 class C (nameOffset:53) (firstTokenOffset:27) (offset:53)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @27
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    importPrefix: ImportPrefixReference
                      name: foo @28
                      period: . @31
                      element: <testLibraryFragment>::@prefix::foo
                    name: A @32
                    typeArguments: TypeArgumentList
                      leftBracket: < @33
                      arguments
                        NamedType
                          name: int @34
                          element: dart:core::@class::int
                          type: int
                      rightBracket: > @37
                    element: package:test/foo.dart::@class::A
                    type: A<int>
                  selector: ConstructorSelector
                    period: . @38
                    name2: named @39
                  element: SubstitutedConstructorElementImpl
                    baseElement: package:test/foo.dart::@class::A::@constructor::named
                    substitution: {T: int}
                argumentList: ArgumentList
                  leftParenthesis: ( @44
                  rightParenthesis: ) @45
                staticType: A<int>
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @28
                  element: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @31
                identifier: SimpleIdentifier
                  token: A @32
                  element: package:test/foo.dart::@class::A
                  staticType: null
                element: package:test/foo.dart::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @33
                arguments
                  NamedType
                    name: int @34
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @37
              period: . @38
              constructorName: SimpleIdentifier
                token: named @39
                element: SubstitutedConstructorElementImpl
                  baseElement: package:test/foo.dart::@class::A::@constructor::named
                  substitution: {T: int}
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @44
                rightParenthesis: ) @45
              element: SubstitutedConstructorElementImpl
                baseElement: package:test/foo.dart::@class::A::@constructor::named
                substitution: {T: int}
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_metadata_constructor_call_named_synthetic_ofClassAlias_generic() async {
    var library = await buildLibrary(r'''
class A {
  const A.named();
}

mixin B {}

class C<T> = A with B;

@C.named()
class D {}
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
            #F2 isConst isOriginDeclaration named (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 18
              periodOffset: 19
        #F3 isMixinApplication class C (nameOffset:50) (firstTokenOffset:44) (offset:50)
          element: <testLibrary>::@class::C
          typeParameters
            #F4 T (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: #E0 T
          constructors
            #F5 isConst isOriginMixinApplication named (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
        #F6 class D (nameOffset:85) (firstTokenOffset:68) (offset:85)
          element: <testLibrary>::@class::D
          metadata
            annotation_0: Annotation
              atSign: @ @68
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: C @69
                    element: <testLibrary>::@class::C
                    type: C<dynamic>
                  selector: ConstructorSelector
                    period: . @70
                    name2: named @71
                  element: SubstitutedConstructorElementImpl
                    baseElement: <testLibrary>::@class::C::@constructor::named
                    substitution: {T: dynamic}
                argumentList: ArgumentList
                  leftParenthesis: ( @76
                  rightParenthesis: ) @77
                staticType: C<dynamic>
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: C @69
                  element: <testLibrary>::@class::C
                  staticType: null
                period: . @70
                identifier: SimpleIdentifier
                  token: named @71
                  element: SubstitutedConstructorElementImpl
                    baseElement: <testLibrary>::@class::C::@constructor::named
                    substitution: {T: dynamic}
                  staticType: null
                element: SubstitutedConstructorElementImpl
                  baseElement: <testLibrary>::@class::C::@constructor::named
                  substitution: {T: dynamic}
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @76
                rightParenthesis: ) @77
              element: SubstitutedConstructorElementImpl
                baseElement: <testLibrary>::@class::C::@constructor::named
                substitution: {T: dynamic}
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:85)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      mixins
        #F8 mixin B (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@mixin::B
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isConst isOriginDeclaration named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F2
    isMixinApplication isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
      supertype: A
      mixins
        B
      constructors
        hasEnclosingTypeParameterReference isConst isOriginMixinApplication named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F5
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              constructorSelector: ConstructorSelector
                period: . @0
                name2: named @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              period: . @0
              constructorName: SimpleIdentifier
                token: named @0
                element: <testLibrary>::@class::A::@constructor::named
                staticType: null
              element: <testLibrary>::@class::A::@constructor::named
          superConstructor: <testLibrary>::@class::A::@constructor::named
    isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F6
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F7
  mixins
    isSimplyBounded mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F8
      superclassConstraints
        Object
''');
  }

  test_metadata_constructor_call_unnamed() async {
    var library = await buildLibrary(r'''
class A {
  const A(int _);
}

@A(0)
class C {}
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
                #F3 requiredPositional isOriginDeclaration _ (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
        #F4 class C (nameOffset:43) (firstTokenOffset:31) (offset:43)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @31
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @32
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @33
                  arguments2
                    IntegerLiteral
                      literal: 0 @34
                      staticType: int
                  rightParenthesis: ) @35
                staticType: A
              name: SimpleIdentifier
                token: A @32
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @33
                arguments
                  IntegerLiteral
                    literal: 0 @34
                    staticType: int
                rightParenthesis: ) @35
              element: <testLibrary>::@class::A::@constructor::new
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F3
              type: int
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_metadata_constructor_call_unnamed_doubleLiteral() async {
    var library = await buildLibrary(r'''
class A {
  const A(double _);
}

@A(.5)
@A(1e3)
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
                #F3 requiredPositional isOriginDeclaration _ (nameOffset:27) (firstTokenOffset:20) (offset:27)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
      functions
        #F4 isComplete isOriginDeclaration isStatic f (nameOffset:54) (firstTokenOffset:34) (offset:54)
          element: <testLibrary>::@function::f
          metadata
            annotation_0: Annotation
              atSign: @ @34
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @35
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @36
                  arguments2
                    DoubleLiteral
                      literal: .5 @37
                      staticType: double
                  rightParenthesis: ) @39
                staticType: A
              name: SimpleIdentifier
                token: A @35
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @36
                arguments
                  DoubleLiteral
                    literal: .5 @37
                    staticType: double
                rightParenthesis: ) @39
              element: <testLibrary>::@class::A::@constructor::new
            annotation_1: Annotation
              atSign: @ @41
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @42
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @43
                  arguments2
                    DoubleLiteral
                      literal: 1e3 @44
                      staticType: double
                  rightParenthesis: ) @47
                staticType: A
              name: SimpleIdentifier
                token: A @42
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @43
                arguments
                  DoubleLiteral
                    literal: 1e3 @44
                    staticType: double
                rightParenthesis: ) @47
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
            #E0 requiredPositional _
              firstFragment: #F3
              type: double
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F4
      metadata
        annotation_0
        annotation_1
      returnType: void
''');
  }

  test_metadata_constructor_call_unnamed_generic_inference() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A(T _);
}

@A(0)
class C {}
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
            #F3 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
              formalParameters
                #F4 requiredPositional isOriginDeclaration _ (nameOffset:25) (firstTokenOffset:23) (offset:25)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
        #F5 class C (nameOffset:44) (firstTokenOffset:32) (offset:44)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @32
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @33
                    element: <testLibrary>::@class::A
                    type: A<int>
                  element: SubstitutedConstructorElementImpl
                    baseElement: <testLibrary>::@class::A::@constructor::new
                    substitution: {T: int}
                argumentList: ArgumentList
                  leftParenthesis: ( @34
                  arguments2
                    IntegerLiteral
                      literal: 0 @35
                      staticType: int
                  rightParenthesis: ) @36
                staticType: A<int>
              name: SimpleIdentifier
                token: A @33
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @34
                arguments
                  IntegerLiteral
                    literal: 0 @35
                    staticType: int
                rightParenthesis: ) @36
              element: SubstitutedConstructorElementImpl
                baseElement: <testLibrary>::@class::A::@constructor::new
                substitution: {T: int}
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F4
              type: T
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
''');
  }

  test_metadata_constructor_call_unnamed_generic_typeArguments() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A();
}

@A<int>()
class C {}
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
            #F3 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
        #F4 class C (nameOffset:45) (firstTokenOffset:29) (offset:45)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @29
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @30
                    typeArguments: TypeArgumentList
                      leftBracket: < @31
                      arguments
                        NamedType
                          name: int @32
                          element: dart:core::@class::int
                          type: int
                      rightBracket: > @35
                    element: <testLibrary>::@class::A
                    type: A<int>
                  element: SubstitutedConstructorElementImpl
                    baseElement: <testLibrary>::@class::A::@constructor::new
                    substitution: {T: int}
                argumentList: ArgumentList
                  leftParenthesis: ( @36
                  rightParenthesis: ) @37
                staticType: A<int>
              name: SimpleIdentifier
                token: A @30
                element: <testLibrary>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @31
                arguments
                  NamedType
                    name: int @32
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @35
              arguments: ArgumentList
                leftParenthesis: ( @36
                rightParenthesis: ) @37
              element: SubstitutedConstructorElementImpl
                baseElement: <testLibrary>::@class::A::@constructor::new
                substitution: {T: int}
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_metadata_constructor_call_unnamed_prefixed() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  const A(_);
}
''');
    var library = await buildLibrary(r'''
import "foo.dart" as foo;

@foo.A(0)
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix::foo
          fragments: @21
      classes
        #F1 class C (nameOffset:43) (firstTokenOffset:27) (offset:43)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @27
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    importPrefix: ImportPrefixReference
                      name: foo @28
                      period: . @31
                      element: <testLibraryFragment>::@prefix::foo
                    name: A @32
                    element: package:test/foo.dart::@class::A
                    type: A
                  element: package:test/foo.dart::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @33
                  arguments2
                    IntegerLiteral
                      literal: 0 @34
                      staticType: int
                  rightParenthesis: ) @35
                staticType: A
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @28
                  element: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @31
                identifier: SimpleIdentifier
                  token: A @32
                  element: package:test/foo.dart::@class::A
                  staticType: null
                element: package:test/foo.dart::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @33
                arguments
                  IntegerLiteral
                    literal: 0 @34
                    staticType: int
                rightParenthesis: ) @35
              element: package:test/foo.dart::@class::A::@constructor::new
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_metadata_constructor_call_unnamed_prefixed_generic_inference() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A<T> {
  const A(T _);
}
''');
    var library = await buildLibrary(r'''
import "foo.dart" as foo;

@foo.A(0)
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix::foo
          fragments: @21
      classes
        #F1 class C (nameOffset:43) (firstTokenOffset:27) (offset:43)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @27
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    importPrefix: ImportPrefixReference
                      name: foo @28
                      period: . @31
                      element: <testLibraryFragment>::@prefix::foo
                    name: A @32
                    element: package:test/foo.dart::@class::A
                    type: A<int>
                  element: SubstitutedConstructorElementImpl
                    baseElement: package:test/foo.dart::@class::A::@constructor::new
                    substitution: {T: int}
                argumentList: ArgumentList
                  leftParenthesis: ( @33
                  arguments2
                    IntegerLiteral
                      literal: 0 @34
                      staticType: int
                  rightParenthesis: ) @35
                staticType: A<int>
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @28
                  element: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @31
                identifier: SimpleIdentifier
                  token: A @32
                  element: package:test/foo.dart::@class::A
                  staticType: null
                element: package:test/foo.dart::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @33
                arguments
                  IntegerLiteral
                    literal: 0 @34
                    staticType: int
                rightParenthesis: ) @35
              element: SubstitutedConstructorElementImpl
                baseElement: package:test/foo.dart::@class::A::@constructor::new
                substitution: {T: int}
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_metadata_constructor_call_unnamed_prefixed_generic_typeArguments() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A<T> {
  const A();
}
''');
    var library = await buildLibrary(r'''
import "foo.dart" as foo;

@foo.A<int>()
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix::foo
          fragments: @21
      classes
        #F1 class C (nameOffset:47) (firstTokenOffset:27) (offset:47)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @27
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    importPrefix: ImportPrefixReference
                      name: foo @28
                      period: . @31
                      element: <testLibraryFragment>::@prefix::foo
                    name: A @32
                    typeArguments: TypeArgumentList
                      leftBracket: < @33
                      arguments
                        NamedType
                          name: int @34
                          element: dart:core::@class::int
                          type: int
                      rightBracket: > @37
                    element: package:test/foo.dart::@class::A
                    type: A<int>
                  element: SubstitutedConstructorElementImpl
                    baseElement: package:test/foo.dart::@class::A::@constructor::new
                    substitution: {T: int}
                argumentList: ArgumentList
                  leftParenthesis: ( @38
                  rightParenthesis: ) @39
                staticType: A<int>
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @28
                  element: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @31
                identifier: SimpleIdentifier
                  token: A @32
                  element: package:test/foo.dart::@class::A
                  staticType: null
                element: package:test/foo.dart::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @33
                arguments
                  NamedType
                    name: int @34
                    element: dart:core::@class::int
                    type: int
                rightBracket: > @37
              arguments: ArgumentList
                leftParenthesis: ( @38
                rightParenthesis: ) @39
              element: SubstitutedConstructorElementImpl
                baseElement: package:test/foo.dart::@class::A::@constructor::new
                substitution: {T: int}
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_metadata_constructor_call_unnamed_synthetic_ofClassAlias_generic() async {
    var library = await buildLibrary(r'''
class A {
  const A();
}

mixin B {}

class C<T> = A with B;

@C()
class D {}
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
        #F3 isMixinApplication class C (nameOffset:44) (firstTokenOffset:38) (offset:44)
          element: <testLibrary>::@class::C
          typeParameters
            #F4 T (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: #E0 T
          constructors
            #F5 isConst isOriginMixinApplication new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F6 class D (nameOffset:73) (firstTokenOffset:62) (offset:73)
          element: <testLibrary>::@class::D
          metadata
            annotation_0: Annotation
              atSign: @ @62
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: C @63
                    element: <testLibrary>::@class::C
                    type: C<dynamic>
                  element: SubstitutedConstructorElementImpl
                    baseElement: <testLibrary>::@class::C::@constructor::new
                    substitution: {T: dynamic}
                argumentList: ArgumentList
                  leftParenthesis: ( @64
                  rightParenthesis: ) @65
                staticType: C<dynamic>
              name: SimpleIdentifier
                token: C @63
                element: <testLibrary>::@class::C
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @64
                rightParenthesis: ) @65
              element: SubstitutedConstructorElementImpl
                baseElement: <testLibrary>::@class::C::@constructor::new
                substitution: {T: dynamic}
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      mixins
        #F8 mixin B (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@mixin::B
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    isMixinApplication isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
      supertype: A
      mixins
        B
      constructors
        hasEnclosingTypeParameterReference isConst isOriginMixinApplication new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: <testLibrary>::@class::A::@constructor::new
    isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F6
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F7
  mixins
    isSimplyBounded mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F8
      superclassConstraints
        Object
''');
  }

  test_metadata_constructor_call_with_args() async {
    var library = await buildLibrary(r'''
class A {
  const A(x);
}

@A(null)
class C {}
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
                #F3 requiredPositional hasImplicitType isOriginDeclaration x (nameOffset:20) (firstTokenOffset:20) (offset:20)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
        #F4 class C (nameOffset:42) (firstTokenOffset:27) (offset:42)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @27
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @28
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @29
                  arguments2
                    NullLiteral
                      literal: null @30
                      staticType: Null
                  rightParenthesis: ) @34
                staticType: A
              name: SimpleIdentifier
                token: A @28
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @29
                arguments
                  NullLiteral
                    literal: null @30
                    staticType: Null
                rightParenthesis: ) @34
              element: <testLibrary>::@class::A::@constructor::new
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional hasImplicitType x
              firstFragment: #F3
              type: dynamic
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_metadata_constructor_namedArgument() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A({required int value});
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@A(value: 42)
void f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      functions
        #F1 isComplete isOriginDeclaration isStatic f (nameOffset:37) (firstTokenOffset:18) (offset:37)
          element: <testLibrary>::@function::f
          metadata
            annotation_0: Annotation
              atSign: @ @18
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @19
                    element: package:test/a.dart::@class::A
                    type: A
                  element: package:test/a.dart::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @20
                  arguments2
                    NamedArgument
                      name: value @21
                      colon: : @26
                      argumentExpression2: IntegerLiteral
                        literal: 42 @28
                        staticType: int
                  rightParenthesis: ) @30
                staticType: A
              name: SimpleIdentifier
                token: A @19
                element: package:test/a.dart::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @20
                arguments
                  NamedArgument
                    name: value @21
                    colon: : @26
                    argumentExpression: IntegerLiteral
                      literal: 42 @28
                      staticType: int
                rightParenthesis: ) @30
              element: package:test/a.dart::@class::A::@constructor::new
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      metadata
        annotation_0
      returnType: void
''');
  }

  test_metadata_constructorDeclaration_named() async {
    var library = await buildLibrary(r'''
const a = null;

class C {
  @a
  C.named();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          constructors
            #F2 isOriginDeclaration named (nameOffset:36) (firstTokenOffset:29) (offset:36)
              element: <testLibrary>::@class::C::@constructor::named
              metadata
                annotation_0: Annotation
                  atSign: @ @29
                  expression: UnqualifiedNameExpression
                    name: a @30
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @30
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
              typeName: C
              typeNameOffset: 34
              periodOffset: 35
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F4
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isOriginDeclaration named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F2
          metadata
            annotation_0
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_constructorDeclaration_unnamed() async {
    var library = await buildLibrary(r'''
const a = null;

class C {
  @a
  C();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          constructors
            #F2 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@class::C::@constructor::new
              metadata
                annotation_0: Annotation
                  atSign: @ @29
                  expression: UnqualifiedNameExpression
                    name: a @30
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @30
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
              typeName: C
              typeNameOffset: 34
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F4
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          metadata
            annotation_0
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_enumDeclaration_augmentation_inBoth_first() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = 0;

@a
enum A { v }

@b
augment enum A {}
''');
    // Check metadata without asking any other properties.
    var A = library.getEnum('A')!;
    configuration.withCombinedFragmentData(A, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@enum::A
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @27
        expression: UnqualifiedNameExpression
          name: a @28
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @28
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
      annotation_1: Annotation
        atSign: @ @44
        expression: UnqualifiedNameExpression
          name: b @45
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::b
            type: int
          staticType: int
        name: SimpleIdentifier
          token: b @45
          element: <testLibrary>::@getter::b
          staticType: null
        element: <testLibrary>::@getter::b
  fragments
    #F0
      metadata
        annotation_0
    #F1
      metadata
        annotation_1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F0 enum A (nameOffset:35) (firstTokenOffset:27) (offset:35)
          element: <testLibrary>::@enum::A
          metadata
            annotation_0
          nextFragment: #F1
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:39) (firstTokenOffset:39) (offset:39)
              element: <testLibrary>::@enum::A::@field::v
              constantInitializer2: expression_0
                ConstructorInvocation
                  constructorReference: ConstructorReference2
                    typeReference: ConstructorTypeReference
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              constantInitializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@enum::A::@field::values
              constantInitializer2: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements2
                    UnqualifiedNameExpression
                      name: v @-1
                      resolution: GetterInvocationResolution
                        element: <testLibrary>::@enum::A::@getter::v
                        type: A
                      staticType: A
                  elements(v1)
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F1 isAugmentation enum A (nameOffset:60) (firstTokenOffset:44) (offset:60)
          element: <testLibrary>::@enum::A
          metadata
            annotation_1
          previousFragment: #F0
      topLevelVariables
        #F8 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_3
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F9
        #F10 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_4
            IntegerLiteral
              literal: 0 @23
              staticType: int
          inducedGetter: #F11
      getters
        #F9 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F8
        #F11 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F10
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F0
      metadata
        annotation_0
        annotation_1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer2: expression_0
          constantInitializer: expression_1
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer2: expression_2
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: int
      constantInitializer2: expression_3
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F10
      type: int
      constantInitializer2: expression_4
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_exportDirective() async {
    newFile('$testPackageLibPath/foo.dart', r'''
''');

    var library = await buildLibrary(r'''
@a
export 'foo.dart';

const a = 0;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    annotation_0: Annotation
      atSign: @ @0
      expression: UnqualifiedNameExpression
        name: a @1
        resolution: GetterInvocationResolution
          element: <testLibrary>::@getter::a
          type: int
        staticType: int
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/foo.dart
          metadata
            annotation_1: Annotation
              atSign: @ @0
              expression: UnqualifiedNameExpression
                name: a @1
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: a @1
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @33
              staticType: int
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_exportDirective_afterAnnotatedLibraryDirective() async {
    var library = await buildLibrary(r'''
@a
library;
@b
export 'dart:math';

const a = 0;
const b = 1;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    annotation_0: Annotation
      atSign: @ @0
      expression: UnqualifiedNameExpression
        name: a @1
        resolution: GetterInvocationResolution
          element: <testLibrary>::@getter::a
          type: int
        staticType: int
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        dart:math
          metadata
            annotation_1: Annotation
              atSign: @ @12
              expression: UnqualifiedNameExpression
                name: b @13
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::b
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: b @13
                element: <testLibrary>::@getter::b
                staticType: null
              element: <testLibrary>::@getter::b
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:42) (firstTokenOffset:42) (offset:42)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @46
              staticType: int
          inducedGetter: #F2
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:55) (firstTokenOffset:55) (offset:55)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 1 @59
              staticType: int
          inducedGetter: #F4
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F4 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
          element: <testLibrary>::@getter::b
          inducingVariable: #F3
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_extensionDeclaration_augmentation_inBoth_first() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = 0;

@a
extension A on int {}

@b
augment extension A {}
''');
    // Check metadata without asking any other properties.
    var A = library.getExtension('A')!;
    configuration.withCombinedFragmentData(A, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@extension::A
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @27
        expression: UnqualifiedNameExpression
          name: a @28
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @28
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
      annotation_1: Annotation
        atSign: @ @53
        expression: UnqualifiedNameExpression
          name: b @54
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::b
            type: int
          staticType: int
        name: SimpleIdentifier
          token: b @54
          element: <testLibrary>::@getter::b
          staticType: null
        element: <testLibrary>::@getter::b
  fragments
    #F0
      metadata
        annotation_0
    #F1
      metadata
        annotation_1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F0 extension A (nameOffset:40) (firstTokenOffset:27) (offset:40)
          element: <testLibrary>::@extension::A
          metadata
            annotation_0
          nextFragment: #F1
        #F1 isAugmentation extension A (nameOffset:74) (firstTokenOffset:53) (offset:74)
          element: <testLibrary>::@extension::A
          metadata
            annotation_1
          previousFragment: #F0
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F4
        #F5 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 0 @23
              staticType: int
          inducedGetter: #F6
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
        #F6 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F5
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F0
      metadata
        annotation_0
        annotation_1
      extendedType: int
      onDeclaration: dart:core::@class::int
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F5
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_extensionTypeDeclaration_augmentation_inBoth_first() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = 0;

@a
extension type A(int it) {}

@b
augment extension type A {}
''');
    // Check metadata without asking any other properties.
    var A = library.getExtensionType('A')!;
    configuration.withCombinedFragmentData(A, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@extensionType::A
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @27
        expression: UnqualifiedNameExpression
          name: a @28
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @28
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
      annotation_1: Annotation
        atSign: @ @59
        expression: UnqualifiedNameExpression
          name: b @60
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::b
            type: int
          staticType: int
        name: SimpleIdentifier
          token: b @60
          element: <testLibrary>::@getter::b
          staticType: null
        element: <testLibrary>::@getter::b
  fragments
    #F0
      metadata
        annotation_0
    #F1
      metadata
        annotation_1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F0 extension type A (nameOffset:45) (firstTokenOffset:27) (offset:45)
          element: <testLibrary>::@extensionType::A
          metadata
            annotation_0
          nextFragment: #F1
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
          constructors
            #F5 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:45) (offset:45)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 45
              primaryHeaderCodeRange: 46 + 8
              formalParameters
                #F6 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:51) (firstTokenOffset:47) (offset:51)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
        #F1 isAugmentation extension type A (nameOffset:85) (firstTokenOffset:59) (offset:85)
          element: <testLibrary>::@extensionType::A
          metadata
            annotation_1
          previousFragment: #F0
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F8
        #F9 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 0 @23
              staticType: int
          inducedGetter: #F10
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
        #F10 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F9
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F0
      metadata
        annotation_0
        annotation_1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F9
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_fieldDeclaration() async {
    var library = await buildLibrary(r'''
const a = null;

class C {
  @a
  int x;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          fields
            #F2 isOriginDeclaration x (nameOffset:38) (firstTokenOffset:38) (offset:38)
              element: <testLibrary>::@class::C::@field::x
              metadata
                annotation_0: Annotation
                  atSign: @ @29
                  expression: UnqualifiedNameExpression
                    name: a @30
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @30
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::C::@getter::x
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::C::@setter::x
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F8
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
  classes
    hasNonFinalField isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        isOriginDeclaration x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          metadata
            annotation_0
          type: int
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::C::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_fieldFormalParameter() async {
    var library = await buildLibrary(r'''
const a = null;

class C {
  var x;
  C(@a this.x);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          fields
            #F2 hasImplicitType isOriginDeclaration x (nameOffset:33) (firstTokenOffset:33) (offset:33)
              element: <testLibrary>::@class::C::@field::x
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isComplete isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:38) (offset:38)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 38
              formalParameters
                #F6 requiredPositional hasImplicitType isFinal isOriginDeclaration this.x (nameOffset:48) (firstTokenOffset:40) (offset:48)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  metadata
                    annotation_0: Annotation
                      atSign: @ @40
                      expression: UnqualifiedNameExpression
                        name: a @41
                        resolution: GetterInvocationResolution
                          element: <testLibrary>::@getter::a
                          type: dynamic
                        staticType: dynamic
                      name: SimpleIdentifier
                        token: a @41
                        element: <testLibrary>::@getter::a
                        staticType: null
                      element: <testLibrary>::@getter::a
          getters
            #F3 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::C::@getter::x
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::C::@setter::x
              inducingVariable: #F2
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
      topLevelVariables
        #F8 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F9
      getters
        #F9 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F8
  classes
    hasNonFinalField isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional hasImplicitType isFinal this.x
              firstFragment: #F6
              type: dynamic
              metadata
                annotation_0
              field: <testLibrary>::@class::C::@field::x
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_fieldFormalParameter_withDefault() async {
    var library = await buildLibrary(r'''
const a = null;

class C {
  var x;
  C([@a this.x = null]);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          fields
            #F2 hasImplicitType isOriginDeclaration x (nameOffset:33) (firstTokenOffset:33) (offset:33)
              element: <testLibrary>::@class::C::@field::x
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isComplete isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:38) (offset:38)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 38
              formalParameters
                #F6 optionalPositional hasImplicitType isFinal isOriginDeclaration this.x (nameOffset:49) (firstTokenOffset:41) (offset:49)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                  metadata
                    annotation_0: Annotation
                      atSign: @ @41
                      expression: UnqualifiedNameExpression
                        name: a @42
                        resolution: GetterInvocationResolution
                          element: <testLibrary>::@getter::a
                          type: dynamic
                        staticType: dynamic
                      name: SimpleIdentifier
                        token: a @42
                        element: <testLibrary>::@getter::a
                        staticType: null
                      element: <testLibrary>::@getter::a
                  constantInitializer2: expression_0
                    NullLiteral
                      literal: null @53
                      staticType: Null
          getters
            #F3 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::C::@getter::x
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::C::@setter::x
              inducingVariable: #F2
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
      topLevelVariables
        #F8 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_1
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F9
      getters
        #F9 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F8
  classes
    hasNonFinalField isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 optionalPositional hasDefaultValue hasImplicitType isFinal this.x
              firstFragment: #F6
              type: dynamic
              metadata
                annotation_0
              constantInitializer2: expression_0
              field: <testLibrary>::@class::C::@field::x
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F4
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: dynamic
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_functionDeclaration_function() async {
    var library = await buildLibrary(r'''
const a = null;
@a
f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
      functions
        #F3 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:19) (firstTokenOffset:16) (offset:19)
          element: <testLibrary>::@function::f
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: a @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: a @17
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    hasImplicitReturnType isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      metadata
        annotation_0
      returnType: dynamic
''');
  }

  test_metadata_functionDeclaration_getter() async {
    var library = await buildLibrary(r'''
const a = null;
@a
get f => null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F2
        #F3 isOriginGetterSetter isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F4 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:23) (firstTokenOffset:16) (offset:23)
          element: <testLibrary>::@getter::f
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: a @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: a @17
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    isOriginGetterSetter isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::f
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    hasImplicitReturnType isOriginDeclaration isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F4
      metadata
        annotation_0
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_metadata_functionDeclaration_setter() async {
    var library = await buildLibrary(r'''
const a = null;
@a
set f(value) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F2
        #F3 isOriginGetterSetter isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
      setters
        #F4 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:23) (firstTokenOffset:16) (offset:23)
          element: <testLibrary>::@setter::f
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: a @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: a @17
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          formalParameters
            #F5 requiredPositional hasImplicitType isOriginDeclaration value (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    isOriginGetterSetter isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F3
      type: dynamic
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  setters
    hasImplicitReturnType isOriginDeclaration isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F4
      metadata
        annotation_0
      formalParameters
        #E0 requiredPositional hasImplicitType value
          firstFragment: #F5
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_metadata_functionTypeAlias() async {
    var library = await buildLibrary(r'''
const a = null;
@a
typedef F();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:27) (firstTokenOffset:16) (offset:27)
          element: <testLibrary>::@typeAlias::F
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: a @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: a @17
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
      topLevelVariables
        #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F3
      getters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F2
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      metadata
        annotation_0
      aliasedType: dynamic Function()
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_functionTypedFormalParameter() async {
    var library = await buildLibrary(r'''
const a = null;
f(@a g()) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
      functions
        #F3 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@function::f
          formalParameters
            #F4 requiredPositional isOriginDeclaration g (nameOffset:21) (firstTokenOffset:18) (offset:21)
              element: <testLibrary>::@function::f::@formalParameter::g
              metadata
                annotation_0: Annotation
                  atSign: @ @18
                  expression: UnqualifiedNameExpression
                    name: a @19
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @19
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    hasImplicitReturnType isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional g
          firstFragment: #F4
          type: dynamic Function()
          metadata
            annotation_0
      returnType: dynamic
''');
  }

  test_metadata_functionTypedFormalParameter_withDefault() async {
    var library = await buildLibrary(r'''
const a = null;
f([@a g() = null]) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
      functions
        #F3 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@function::f
          formalParameters
            #F4 optionalPositional isOriginDeclaration g (nameOffset:22) (firstTokenOffset:19) (offset:22)
              element: <testLibrary>::@function::f::@formalParameter::g
              metadata
                annotation_0: Annotation
                  atSign: @ @19
                  expression: UnqualifiedNameExpression
                    name: a @20
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @20
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
              constantInitializer2: expression_1
                NullLiteral
                  literal: null @28
                  staticType: Null
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    hasImplicitReturnType isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      formalParameters
        #E0 optionalPositional hasDefaultValue g
          firstFragment: #F4
          type: dynamic Function()
          metadata
            annotation_0
          constantInitializer2: expression_1
      returnType: dynamic
''');
  }

  test_metadata_genericTypeAlias() async {
    var library = await buildLibrary(r'''
const a = null;
const b = null;
@a
@b
typedef F = void Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:46) (firstTokenOffset:32) (offset:46)
          element: <testLibrary>::@typeAlias::F
          metadata
            annotation_0: Annotation
              atSign: @ @32
              expression: UnqualifiedNameExpression
                name: a @33
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: a @33
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
            annotation_1: Annotation
              atSign: @ @35
              expression: UnqualifiedNameExpression
                name: b @36
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::b
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: b @36
                element: <testLibrary>::@getter::b
                staticType: null
              element: <testLibrary>::@getter::b
      topLevelVariables
        #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F3
        #F4 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
          inducedGetter: #F5
      getters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F2
        #F5 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::b
          inducingVariable: #F4
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      metadata
        annotation_0
        annotation_1
      aliasedType: void Function()
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: dynamic
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_importDirective() async {
    newFile('$testPackageLibPath/foo.dart', r'''
''');

    var library = await buildLibrary(r'''
@a
import 'foo.dart';

const a = 0;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    annotation_0: Annotation
      atSign: @ @0
      expression: UnqualifiedNameExpression
        name: a @1
        resolution: GetterInvocationResolution
          element: <testLibrary>::@getter::a
          type: int
        staticType: int
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
          metadata
            annotation_1: Annotation
              atSign: @ @0
              expression: UnqualifiedNameExpression
                name: a @1
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: a @1
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @33
              staticType: int
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_importDirective_afterAnnotatedImportDirective() async {
    var library = await buildLibrary(r'''
@a
import 'dart:math';
@b
import 'dart:async';

const a = 0;
const b = 1;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    annotation_0: Annotation
      atSign: @ @0
      expression: UnqualifiedNameExpression
        name: a @1
        resolution: GetterInvocationResolution
          element: <testLibrary>::@getter::a
          type: int
        staticType: int
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:math
          metadata
            annotation_1: Annotation
              atSign: @ @0
              expression: UnqualifiedNameExpression
                name: a @1
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: a @1
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
        dart:async
          metadata
            annotation_2: Annotation
              atSign: @ @23
              expression: UnqualifiedNameExpression
                name: b @24
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::b
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: b @24
                element: <testLibrary>::@getter::b
                staticType: null
              element: <testLibrary>::@getter::b
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:54) (firstTokenOffset:54) (offset:54)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @58
              staticType: int
          inducedGetter: #F2
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:67) (firstTokenOffset:67) (offset:67)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 1 @71
              staticType: int
          inducedGetter: #F4
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F4 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
          element: <testLibrary>::@getter::b
          inducingVariable: #F3
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_importDirective_afterAnnotatedLibraryDirective() async {
    var library = await buildLibrary(r'''
@a
library;
@b
import 'dart:math';

const a = 0;
const b = 1;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    annotation_0: Annotation
      atSign: @ @0
      expression: UnqualifiedNameExpression
        name: a @1
        resolution: GetterInvocationResolution
          element: <testLibrary>::@getter::a
          type: int
        staticType: int
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:math
          metadata
            annotation_1: Annotation
              atSign: @ @12
              expression: UnqualifiedNameExpression
                name: b @13
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::b
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: b @13
                element: <testLibrary>::@getter::b
                staticType: null
              element: <testLibrary>::@getter::b
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:42) (firstTokenOffset:42) (offset:42)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @46
              staticType: int
          inducedGetter: #F2
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:55) (firstTokenOffset:55) (offset:55)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 1 @59
              staticType: int
          inducedGetter: #F4
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F4 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
          element: <testLibrary>::@getter::b
          inducingVariable: #F3
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_importDirective_inPart_afterAnnotatedPartOfDirective() async {
    newFile('$testPackageLibPath/a.dart', r'''
@a
part of 'test.dart';
@b
import 'dart:math';
''');

    var library = await buildLibrary(r'''
part 'a.dart';

const a = 0;
const b = 1;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
      topLevelVariables
        #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @26
              staticType: int
          inducedGetter: #F3
        #F4 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:35) (firstTokenOffset:35) (offset:35)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 1 @39
              staticType: int
          inducedGetter: #F5
      getters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::a
          inducingVariable: #F2
        #F5 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
          element: <testLibrary>::@getter::b
          inducingVariable: #F4
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      libraryImports
        dart:math
          metadata
            annotation_0: Annotation
              atSign: @ @24
              expression: UnqualifiedNameExpression
                name: b @25
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::b
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: b @25
                element: <testLibrary>::@getter::b
                staticType: null
              element: <testLibrary>::@getter::b
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_inAliasedElement_formalParameter() async {
    var library = await buildLibrary(r'''
const a = 42;
typedef F = void Function(@a int first)
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:22) (firstTokenOffset:14) (offset:22)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 42 @10
              staticType: int
          inducedGetter: #F3
      getters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F2
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function(int)
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_inAliasedElement_formalParameter2() async {
    var library = await buildLibrary(r'''
const a = 42;
typedef F = void Function(int foo(@a int bar))
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:22) (firstTokenOffset:14) (offset:22)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 42 @10
              staticType: int
          inducedGetter: #F3
      getters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F2
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function(int Function(int))
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_inAliasedElement_typeParameter() async {
    var library = await buildLibrary(r'''
const a = 42;
typedef F = void Function<@a T>(int first)
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:22) (firstTokenOffset:14) (offset:22)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 42 @10
              staticType: int
          inducedGetter: #F3
      getters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F2
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function<T>(int)
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_invalid_classDeclaration() async {
    var library = await buildLibrary(r'''
f(_) {}

@f(42)
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:22) (firstTokenOffset:9) (offset:22)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @9
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: f @10
                    element: <testLibrary>::@function::f
                    type: InvalidType
                  element: <null>
                argumentList: ArgumentList
                  leftParenthesis: ( @11
                  arguments2
                    IntegerLiteral
                      literal: 42 @12
                      staticType: int
                  rightParenthesis: ) @14
                staticType: InvalidType
              name: SimpleIdentifier
                token: f @10
                element: <testLibrary>::@function::f
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @11
                arguments
                  IntegerLiteral
                    literal: 42 @12
                    staticType: int
                rightParenthesis: ) @14
              element: <null>
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      functions
        #F3 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F4 requiredPositional hasImplicitType isOriginDeclaration _ (nameOffset:2) (firstTokenOffset:2) (offset:2)
              element: <testLibrary>::@function::f::@formalParameter::_
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  functions
    hasImplicitReturnType isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional hasImplicitType _
          firstFragment: #F4
          type: dynamic
      returnType: dynamic
''');
  }

  test_metadata_library_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');
    var library = await buildLibrary(r'''
@deprecated
part 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    annotation_0: Annotation
      atSign: @ @0
      expression: UnqualifiedNameExpression
        name: deprecated @1
        resolution: GetterInvocationResolution
          element: dart:core::@getter::deprecated
          type: Deprecated
        staticType: Deprecated
      name: SimpleIdentifier
        token: deprecated @1
        element: dart:core::@getter::deprecated
        staticType: null
      element: dart:core::@getter::deprecated
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 12
          metadata
            annotation_1: Annotation
              atSign: @ @0
              expression: UnqualifiedNameExpression
                name: deprecated @1
                resolution: GetterInvocationResolution
                  element: dart:core::@getter::deprecated
                  type: Deprecated
                staticType: Deprecated
              name: SimpleIdentifier
                token: deprecated @1
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
''');
  }

  /// Even though the target is not a part, metadata is available.
  test_metadata_library_part_notPart() async {
    var library = await buildLibrary(r'''
@deprecated
part 'dart:math';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    annotation_0: Annotation
      atSign: @ @0
      expression: UnqualifiedNameExpression
        name: deprecated @1
        resolution: GetterInvocationResolution
          element: dart:core::@getter::deprecated
          type: Deprecated
        staticType: Deprecated
      name: SimpleIdentifier
        token: deprecated @1
        element: dart:core::@getter::deprecated
        staticType: null
      element: dart:core::@getter::deprecated
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      parts
        part_0
          uri: source 'dart:math'
          partKeywordOffset: 12
          metadata
            annotation_1: Annotation
              atSign: @ @0
              expression: UnqualifiedNameExpression
                name: deprecated @1
                resolution: GetterInvocationResolution
                  element: dart:core::@getter::deprecated
                  type: Deprecated
                staticType: Deprecated
              name: SimpleIdentifier
                token: deprecated @1
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
''');
  }

  test_metadata_libraryDirective() async {
    var library = await buildLibrary(r'''
@a
library L;

const a = null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: L
  metadata
    annotation_0: Annotation
      atSign: @ @0
      expression: UnqualifiedNameExpression
        name: a @1
        resolution: GetterInvocationResolution
          element: <testLibrary>::@getter::a
          type: dynamic
        staticType: dynamic
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:11)
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @25
              staticType: Null
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_methodDeclaration_getter() async {
    var library = await buildLibrary(r'''
const a = null;

class C {
  @a
  get m => null;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          fields
            #F2 isOriginGetterSetter m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@field::m
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:38) (firstTokenOffset:29) (offset:38)
              element: <testLibrary>::@class::C::@getter::m
              metadata
                annotation_0: Annotation
                  atSign: @ @29
                  expression: UnqualifiedNameExpression
                    name: a @30
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @30
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
      topLevelVariables
        #F5 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F6
      getters
        #F6 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F5
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        isOriginGetterSetter m
          reference: <testLibrary>::@class::C::@field::m
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::m
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        hasImplicitReturnType isOriginDeclaration m
          reference: <testLibrary>::@class::C::@getter::m
          firstFragment: #F4
          metadata
            annotation_0
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::m
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F5
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_methodDeclaration_method() async {
    var library = await buildLibrary(r'''
const a = null;
const b = null;

class C {
  @a
  @b
  m() {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::C
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:55) (firstTokenOffset:45) (offset:55)
              element: <testLibrary>::@class::C::@method::m
              metadata
                annotation_0: Annotation
                  atSign: @ @45
                  expression: UnqualifiedNameExpression
                    name: a @46
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @46
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
                annotation_1: Annotation
                  atSign: @ @50
                  expression: UnqualifiedNameExpression
                    name: b @51
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::b
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: b @51
                    element: <testLibrary>::@getter::b
                    staticType: null
                  element: <testLibrary>::@getter::b
      topLevelVariables
        #F4 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F5
        #F6 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
          inducedGetter: #F7
      getters
        #F5 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F4
        #F7 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::b
          inducingVariable: #F6
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        hasImplicitReturnType isOriginDeclaration m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F3
          metadata
            annotation_0
            annotation_1
          returnType: dynamic
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F6
      type: dynamic
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F7
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_methodDeclaration_method_mixin() async {
    var library = await buildLibrary(r'''
const a = null;
const b = null;

mixin M {
  @a
  @b
  m() {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@mixin::M
          methods
            #F2 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:55) (firstTokenOffset:45) (offset:55)
              element: <testLibrary>::@mixin::M::@method::m
              metadata
                annotation_0: Annotation
                  atSign: @ @45
                  expression: UnqualifiedNameExpression
                    name: a @46
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @46
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
                annotation_1: Annotation
                  atSign: @ @50
                  expression: UnqualifiedNameExpression
                    name: b @51
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::b
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: b @51
                    element: <testLibrary>::@getter::b
                    staticType: null
                  element: <testLibrary>::@getter::b
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F4
        #F5 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
          inducedGetter: #F6
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
        #F6 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::b
          inducingVariable: #F5
  mixins
    isSimplyBounded mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        hasImplicitReturnType isOriginDeclaration m
          reference: <testLibrary>::@mixin::M::@method::m
          firstFragment: #F2
          metadata
            annotation_0
            annotation_1
          returnType: dynamic
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F5
      type: dynamic
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_methodDeclaration_setter() async {
    var library = await buildLibrary(r'''
const a = null;

class C {
  @a
  set m(value) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          fields
            #F2 isOriginGetterSetter m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@field::m
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:38) (firstTokenOffset:29) (offset:38)
              element: <testLibrary>::@class::C::@setter::m
              metadata
                annotation_0: Annotation
                  atSign: @ @29
                  expression: UnqualifiedNameExpression
                    name: a @30
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @30
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
              formalParameters
                #F5 requiredPositional hasImplicitType isOriginDeclaration value (nameOffset:40) (firstTokenOffset:40) (offset:40)
                  element: <testLibrary>::@class::C::@setter::m::@formalParameter::value
      topLevelVariables
        #F6 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F7
      getters
        #F7 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F6
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        isOriginGetterSetter m
          reference: <testLibrary>::@class::C::@field::m
          firstFragment: #F2
          type: dynamic
          setter: <testLibrary>::@class::C::@setter::m
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      setters
        hasImplicitReturnType isOriginDeclaration m
          reference: <testLibrary>::@class::C::@setter::m
          firstFragment: #F4
          metadata
            annotation_0
          formalParameters
            #E0 requiredPositional hasImplicitType value
              firstFragment: #F5
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::m
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F6
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F7
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_mixin_scope() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
mixin M<@foo T> {
  static const foo = 1;
  @foo
  void bar() {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:27) (firstTokenOffset:16) (offset:27)
          element: <testLibrary>::@mixin::M
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: foo @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          typeParameters
            #F2 T (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: #E0 T
              metadata
                annotation_1: Annotation
                  atSign: @ @29
                  expression: UnqualifiedNameExpression
                    name: foo @30
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @30
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
          fields
            #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:54) (firstTokenOffset:54) (offset:54)
              element: <testLibrary>::@mixin::M::@field::foo
              constantInitializer2: expression_0
                IntegerLiteral
                  literal: 1 @60
                  staticType: int
              inducedGetter: #F4
          getters
            #F4 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@mixin::M::@getter::foo
              inducingVariable: #F3
          methods
            #F5 isComplete isOriginDeclaration bar (nameOffset:77) (firstTokenOffset:65) (offset:77)
              element: <testLibrary>::@mixin::M::@method::bar
              metadata
                annotation_2: Annotation
                  atSign: @ @65
                  expression: UnqualifiedNameExpression
                    name: foo @66
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@mixin::M::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @66
                    element: <testLibrary>::@mixin::M::@getter::foo
                    staticType: null
                  element: <testLibrary>::@mixin::M::@getter::foo
      topLevelVariables
        #F6 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F7
      getters
        #F7 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F6
  mixins
    isSimplyBounded mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      metadata
        annotation_0
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            annotation_1
      superclassConstraints
        Object
      fields
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F3
          type: int
          constantInitializer2: expression_0
          getter: <testLibrary>::@mixin::M::@getter::foo
      getters
        isOriginVariable isStatic foo
          reference: <testLibrary>::@mixin::M::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@mixin::M::@field::foo
      methods
        isOriginDeclaration bar
          reference: <testLibrary>::@mixin::M::@method::bar
          firstFragment: #F5
          metadata
            annotation_2
          returnType: void
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F6
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_mixinDeclaration() async {
    var library = await buildLibrary(r'''
const a = null;
const b = null;

@a
@b
mixin M {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:45) (firstTokenOffset:33) (offset:45)
          element: <testLibrary>::@mixin::M
          metadata
            annotation_0: Annotation
              atSign: @ @33
              expression: UnqualifiedNameExpression
                name: a @34
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: a @34
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
            annotation_1: Annotation
              atSign: @ @36
              expression: UnqualifiedNameExpression
                name: b @37
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::b
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: b @37
                element: <testLibrary>::@getter::b
                staticType: null
              element: <testLibrary>::@getter::b
      topLevelVariables
        #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F3
        #F4 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            NullLiteral
              literal: null @26
              staticType: Null
          inducedGetter: #F5
      getters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F2
        #F5 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::b
          inducingVariable: #F4
  mixins
    isSimplyBounded mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      metadata
        annotation_0
        annotation_1
      superclassConstraints
        Object
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: dynamic
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_mixinDeclaration_augmentation_inBoth_first() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = 0;

@a
mixin A {}

@b
augment mixin A {}
''');
    // Check metadata without asking any other properties.
    var A = library.getMixin('A')!;
    configuration.withCombinedFragmentData(A, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@mixin::A
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @27
        expression: UnqualifiedNameExpression
          name: a @28
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @28
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
      annotation_1: Annotation
        atSign: @ @42
        expression: UnqualifiedNameExpression
          name: b @43
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::b
            type: int
          staticType: int
        name: SimpleIdentifier
          token: b @43
          element: <testLibrary>::@getter::b
          staticType: null
        element: <testLibrary>::@getter::b
  fragments
    #F0
      metadata
        annotation_0
    #F1
      metadata
        annotation_1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F0 mixin A (nameOffset:36) (firstTokenOffset:27) (offset:36)
          element: <testLibrary>::@mixin::A
          metadata
            annotation_0
          nextFragment: #F1
        #F1 isAugmentation mixin A (nameOffset:59) (firstTokenOffset:42) (offset:59)
          element: <testLibrary>::@mixin::A
          metadata
            annotation_1
          previousFragment: #F0
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F4
        #F5 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 0 @23
              staticType: int
          inducedGetter: #F6
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
        #F6 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F5
  mixins
    isSimplyBounded mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F0
      metadata
        annotation_0
        annotation_1
      superclassConstraints
        Object
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F5
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_offsets_onClass() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
class A<@foo T> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:27) (firstTokenOffset:16) (offset:27)
          element: <testLibrary>::@class::A
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: foo @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          typeParameters
            #F2 T (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: #E0 T
              metadata
                annotation_1: Annotation
                  atSign: @ @29
                  expression: UnqualifiedNameExpression
                    name: foo @30
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @30
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      topLevelVariables
        #F4 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F5
      getters
        #F5 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F4
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      metadata
        annotation_0
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            annotation_1
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F4
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onClassConstructor() async {
    var library = await buildLibrary(r'''
const foo = 0;

class A {
  @foo
  A(@foo int a);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:28) (offset:35)
              element: <testLibrary>::@class::A::@constructor::new
              metadata
                annotation_0: Annotation
                  atSign: @ @28
                  expression: UnqualifiedNameExpression
                    name: foo @29
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
              typeName: A
              typeNameOffset: 35
              formalParameters
                #F3 requiredPositional isOriginDeclaration a (nameOffset:46) (firstTokenOffset:37) (offset:46)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                  metadata
                    annotation_1: Annotation
                      atSign: @ @37
                      expression: UnqualifiedNameExpression
                        name: foo @38
                        resolution: GetterInvocationResolution
                          element: <testLibrary>::@getter::foo
                          type: int
                        staticType: int
                      name: SimpleIdentifier
                        token: foo @38
                        element: <testLibrary>::@getter::foo
                        staticType: null
                      element: <testLibrary>::@getter::foo
      topLevelVariables
        #F4 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F5
      getters
        #F5 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F4
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          metadata
            annotation_0
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
              type: int
              metadata
                annotation_1
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F4
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onClassGetter() async {
    var library = await buildLibrary(r'''
const foo = 0;

class A {
  @foo
  int get getter => 0;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter getter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@field::getter
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginDeclaration getter (nameOffset:43) (firstTokenOffset:28) (offset:43)
              element: <testLibrary>::@class::A::@getter::getter
              metadata
                annotation_0: Annotation
                  atSign: @ @28
                  expression: UnqualifiedNameExpression
                    name: foo @29
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
      topLevelVariables
        #F5 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F6
      getters
        #F6 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F5
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter getter
          reference: <testLibrary>::@class::A::@field::getter
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::getter
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        isOriginDeclaration getter
          reference: <testLibrary>::@class::A::@getter::getter
          firstFragment: #F4
          metadata
            annotation_0
          returnType: int
          variable: <testLibrary>::@class::A::@field::getter
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F5
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onClassMethod() async {
    var library = await buildLibrary(r'''
const foo = 0;

class A {
  @foo
  void method<@foo T>(@foo int a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isComplete isOriginDeclaration method (nameOffset:40) (firstTokenOffset:28) (offset:40)
              element: <testLibrary>::@class::A::@method::method
              metadata
                annotation_0: Annotation
                  atSign: @ @28
                  expression: UnqualifiedNameExpression
                    name: foo @29
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
              typeParameters
                #F4 T (nameOffset:52) (firstTokenOffset:47) (offset:52)
                  element: #E0 T
                  metadata
                    annotation_1: Annotation
                      atSign: @ @47
                      expression: UnqualifiedNameExpression
                        name: foo @48
                        resolution: GetterInvocationResolution
                          element: <testLibrary>::@getter::foo
                          type: int
                        staticType: int
                      name: SimpleIdentifier
                        token: foo @48
                        element: <testLibrary>::@getter::foo
                        staticType: null
                      element: <testLibrary>::@getter::foo
              formalParameters
                #F5 requiredPositional isOriginDeclaration a (nameOffset:64) (firstTokenOffset:55) (offset:64)
                  element: <testLibrary>::@class::A::@method::method::@formalParameter::a
                  metadata
                    annotation_2: Annotation
                      atSign: @ @55
                      expression: UnqualifiedNameExpression
                        name: foo @56
                        resolution: GetterInvocationResolution
                          element: <testLibrary>::@getter::foo
                          type: int
                        staticType: int
                      name: SimpleIdentifier
                        token: foo @56
                        element: <testLibrary>::@getter::foo
                        staticType: null
                      element: <testLibrary>::@getter::foo
      topLevelVariables
        #F6 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F7
      getters
        #F7 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F6
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration method
          reference: <testLibrary>::@class::A::@method::method
          firstFragment: #F3
          metadata
            annotation_0
          typeParameters
            #E0 T
              firstFragment: #F4
              metadata
                annotation_1
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F5
              type: int
              metadata
                annotation_2
          returnType: void
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F6
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onClassSetter() async {
    var library = await buildLibrary(r'''
const foo = 0;

class A {
  @foo
  set setter(@foo int a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginGetterSetter setter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@field::setter
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F4 hasImplicitReturnType isComplete isOriginDeclaration setter (nameOffset:39) (firstTokenOffset:28) (offset:39)
              element: <testLibrary>::@class::A::@setter::setter
              metadata
                annotation_0: Annotation
                  atSign: @ @28
                  expression: UnqualifiedNameExpression
                    name: foo @29
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
              formalParameters
                #F5 requiredPositional isOriginDeclaration a (nameOffset:55) (firstTokenOffset:46) (offset:55)
                  element: <testLibrary>::@class::A::@setter::setter::@formalParameter::a
                  metadata
                    annotation_1: Annotation
                      atSign: @ @46
                      expression: UnqualifiedNameExpression
                        name: foo @47
                        resolution: GetterInvocationResolution
                          element: <testLibrary>::@getter::foo
                          type: int
                        staticType: int
                      name: SimpleIdentifier
                        token: foo @47
                        element: <testLibrary>::@getter::foo
                        staticType: null
                      element: <testLibrary>::@getter::foo
      topLevelVariables
        #F6 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F7
      getters
        #F7 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F6
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter setter
          reference: <testLibrary>::@class::A::@field::setter
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::A::@setter::setter
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      setters
        hasImplicitReturnType isOriginDeclaration setter
          reference: <testLibrary>::@class::A::@setter::setter
          firstFragment: #F4
          metadata
            annotation_0
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F5
              type: int
              metadata
                annotation_1
          returnType: void
          variable: <testLibrary>::@class::A::@field::setter
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F6
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onClassTypeAlias() async {
    var library = await buildLibrary(r'''
const foo = 0;

class A {}

mixin M {}

@foo
class B<@foo T> = A with M;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 isMixinApplication class B (nameOffset:51) (firstTokenOffset:40) (offset:51)
          element: <testLibrary>::@class::B
          metadata
            annotation_0: Annotation
              atSign: @ @40
              expression: UnqualifiedNameExpression
                name: foo @41
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @41
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          typeParameters
            #F4 T (nameOffset:58) (firstTokenOffset:53) (offset:58)
              element: #E0 T
              metadata
                annotation_1: Annotation
                  atSign: @ @53
                  expression: UnqualifiedNameExpression
                    name: foo @54
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @54
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
          constructors
            #F5 isOriginMixinApplication new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      mixins
        #F6 mixin M (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@mixin::M
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F8
      getters
        #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F7
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    isMixinApplication isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      metadata
        annotation_0
      typeParameters
        #E0 T
          firstFragment: #F4
          metadata
            annotation_1
      supertype: A
      mixins
        M
      constructors
        hasEnclosingTypeParameterReference isOriginMixinApplication new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: <testLibrary>::@class::A::@constructor::new
  mixins
    isSimplyBounded mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F6
      superclassConstraints
        Object
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F7
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onEnum() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
enum E {
  @foo
  e1,
  e2,
  @foo
  e3,
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:26) (firstTokenOffset:16) (offset:26)
          element: <testLibrary>::@enum::E
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: foo @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic e1 (nameOffset:39) (firstTokenOffset:32) (offset:39)
              element: <testLibrary>::@enum::E::@field::e1
              metadata
                annotation_1: Annotation
                  atSign: @ @32
                  expression: UnqualifiedNameExpression
                    name: foo @33
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @33
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
              constantInitializer2: expression_0
                ConstructorInvocation
                  constructorReference: ConstructorReference2
                    typeReference: ConstructorTypeReference
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              constantInitializer: expression_1
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
              inducedGetter: #F3
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic e2 (nameOffset:45) (firstTokenOffset:45) (offset:45)
              element: <testLibrary>::@enum::E::@field::e2
              constantInitializer2: expression_2
                ConstructorInvocation
                  constructorReference: ConstructorReference2
                    typeReference: ConstructorTypeReference
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              constantInitializer: expression_3
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
              inducedGetter: #F5
            #F6 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic e3 (nameOffset:58) (firstTokenOffset:51) (offset:58)
              element: <testLibrary>::@enum::E::@field::e3
              metadata
                annotation_2: Annotation
                  atSign: @ @51
                  expression: UnqualifiedNameExpression
                    name: foo @52
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @52
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
              constantInitializer2: expression_4
                ConstructorInvocation
                  constructorReference: ConstructorReference2
                    typeReference: ConstructorTypeReference
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              constantInitializer: expression_5
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
              inducedGetter: #F7
            #F8 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@field::values
              constantInitializer2: expression_6
                ListLiteral
                  leftBracket: [ @0
                  elements2
                    UnqualifiedNameExpression
                      name: e1 @-1
                      resolution: GetterInvocationResolution
                        element: <testLibrary>::@enum::E::@getter::e1
                        type: E
                      staticType: E
                    UnqualifiedNameExpression
                      name: e2 @-1
                      resolution: GetterInvocationResolution
                        element: <testLibrary>::@enum::E::@getter::e2
                        type: E
                      staticType: E
                    UnqualifiedNameExpression
                      name: e3 @-1
                      resolution: GetterInvocationResolution
                        element: <testLibrary>::@enum::E::@getter::e3
                        type: E
                      staticType: E
                  elements(v1)
                    SimpleIdentifier
                      token: e1 @-1
                      element: <testLibrary>::@enum::E::@getter::e1
                      staticType: E
                    SimpleIdentifier
                      token: e2 @-1
                      element: <testLibrary>::@enum::E::@getter::e2
                      staticType: E
                    SimpleIdentifier
                      token: e3 @-1
                      element: <testLibrary>::@enum::E::@getter::e3
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F9
          constructors
            #F10 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic e1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@enum::E::@getter::e1
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic e2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@enum::E::@getter::e2
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic e3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@enum::E::@getter::e3
              inducingVariable: #F6
            #F9 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F8
      topLevelVariables
        #F11 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_7
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F12
      getters
        #F12 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F11
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      metadata
        annotation_0
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer e1
          reference: <testLibrary>::@enum::E::@field::e1
          firstFragment: #F2
          metadata
            annotation_1
          type: E
          constantInitializer2: expression_0
          constantInitializer: expression_1
          getter: <testLibrary>::@enum::E::@getter::e1
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer e2
          reference: <testLibrary>::@enum::E::@field::e2
          firstFragment: #F4
          type: E
          constantInitializer2: expression_2
          constantInitializer: expression_3
          getter: <testLibrary>::@enum::E::@getter::e2
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer e3
          reference: <testLibrary>::@enum::E::@field::e3
          firstFragment: #F6
          metadata
            annotation_2
          type: E
          constantInitializer2: expression_4
          constantInitializer: expression_5
          getter: <testLibrary>::@enum::E::@getter::e3
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F8
          type: List<E>
          constantInitializer2: expression_6
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic e1
          reference: <testLibrary>::@enum::E::@getter::e1
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::e1
        isOriginVariable isStatic e2
          reference: <testLibrary>::@enum::E::@getter::e2
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::e2
        isOriginVariable isStatic e3
          reference: <testLibrary>::@enum::E::@getter::e3
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::e3
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F11
      type: int
      constantInitializer2: expression_7
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onExtension() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
extension E<@foo T> on List<T> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extension::E
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: foo @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          typeParameters
            #F2 T (nameOffset:38) (firstTokenOffset:33) (offset:38)
              element: #E0 T
              metadata
                annotation_1: Annotation
                  atSign: @ @33
                  expression: UnqualifiedNameExpression
                    name: foo @34
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @34
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F4
      getters
        #F4 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F3
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      metadata
        annotation_0
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            annotation_1
      extendedType: List<T>
      onDeclaration: dart:core::@class::List
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onFieldDeclaration() async {
    var library = await buildLibrary(r'''
const foo = 0;

class A {
  @foo
  static isStatic = 1;

  @foo
  static const isStaticConst = 2;

  @foo
  var isInstance = 3;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::A
          fields
            #F2 hasImplicitType hasInitializer isOriginDeclaration isStatic isStatic (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@class::A::@field::isStatic
              metadata
                annotation_0: Annotation
                  atSign: @ @28
                  expression: UnqualifiedNameExpression
                    name: foo @29
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
              inducedGetter: #F3
              inducedSetter: #F4
            #F5 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isStaticConst (nameOffset:79) (firstTokenOffset:79) (offset:79)
              element: <testLibrary>::@class::A::@field::isStaticConst
              metadata
                annotation_1: Annotation
                  atSign: @ @59
                  expression: UnqualifiedNameExpression
                    name: foo @60
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @60
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
              constantInitializer2: expression_0
                IntegerLiteral
                  literal: 2 @95
                  staticType: int
              inducedGetter: #F6
            #F7 hasImplicitType hasInitializer isOriginDeclaration isInstance (nameOffset:112) (firstTokenOffset:112) (offset:112)
              element: <testLibrary>::@class::A::@field::isInstance
              metadata
                annotation_2: Annotation
                  atSign: @ @101
                  expression: UnqualifiedNameExpression
                    name: foo @102
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @102
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
              inducedGetter: #F8
              inducedSetter: #F9
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable isStatic isStatic (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::A::@getter::isStatic
              inducingVariable: #F2
            #F6 isComplete isOriginVariable isStatic isStaticConst (nameOffset:<null>) (firstTokenOffset:<null>) (offset:79)
              element: <testLibrary>::@class::A::@getter::isStaticConst
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isInstance (nameOffset:<null>) (firstTokenOffset:<null>) (offset:112)
              element: <testLibrary>::@class::A::@getter::isInstance
              inducingVariable: #F7
          setters
            #F4 isComplete isOriginVariable isStatic isStatic (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::A::@setter::isStatic
              inducingVariable: #F2
              formalParameters
                #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
                  element: <testLibrary>::@class::A::@setter::isStatic::@formalParameter::value
            #F9 isComplete isOriginVariable isInstance (nameOffset:<null>) (firstTokenOffset:<null>) (offset:112)
              element: <testLibrary>::@class::A::@setter::isInstance
              inducingVariable: #F7
              formalParameters
                #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:112)
                  element: <testLibrary>::@class::A::@setter::isInstance::@formalParameter::value
      topLevelVariables
        #F13 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F14
      getters
        #F14 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F13
  classes
    hasNonFinalField isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer isStatic
          reference: <testLibrary>::@class::A::@field::isStatic
          firstFragment: #F2
          metadata
            annotation_0
          type: int
          getter: <testLibrary>::@class::A::@getter::isStatic
          setter: <testLibrary>::@class::A::@setter::isStatic
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer isStaticConst
          reference: <testLibrary>::@class::A::@field::isStaticConst
          firstFragment: #F5
          metadata
            annotation_1
          type: int
          constantInitializer2: expression_0
          getter: <testLibrary>::@class::A::@getter::isStaticConst
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer isInstance
          reference: <testLibrary>::@class::A::@field::isInstance
          firstFragment: #F7
          metadata
            annotation_2
          type: int
          getter: <testLibrary>::@class::A::@getter::isInstance
          setter: <testLibrary>::@class::A::@setter::isInstance
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F10
      getters
        isOriginVariable isStatic isStatic
          reference: <testLibrary>::@class::A::@getter::isStatic
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::isStatic
        isOriginVariable isStatic isStaticConst
          reference: <testLibrary>::@class::A::@getter::isStaticConst
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::isStaticConst
        isOriginVariable isInstance
          reference: <testLibrary>::@class::A::@getter::isInstance
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::A::@field::isInstance
      setters
        isOriginVariable isStatic isStatic
          reference: <testLibrary>::@class::A::@setter::isStatic
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::isStatic
        isOriginVariable isInstance
          reference: <testLibrary>::@class::A::@setter::isInstance
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::isInstance
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F13
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onLibrary() async {
    var library = await buildLibrary(r'''
/// Some documentation.
@foo
library my.lib;

const foo = 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: my.lib
  documentationComment: /// Some documentation.
  metadata
    annotation_0: Annotation
      atSign: @ @24
      expression: UnqualifiedNameExpression
        name: foo @25
        resolution: GetterInvocationResolution
          element: <testLibrary>::@getter::foo
          type: int
        staticType: int
      name: SimpleIdentifier
        token: foo @25
        element: <testLibrary>::@getter::foo
        staticType: null
      element: <testLibrary>::@getter::foo
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:37)
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:52) (firstTokenOffset:52) (offset:52)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @58
              staticType: int
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F1
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onMixin() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
mixin A<@foo T> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:27) (firstTokenOffset:16) (offset:27)
          element: <testLibrary>::@mixin::A
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: foo @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          typeParameters
            #F2 T (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: #E0 T
              metadata
                annotation_1: Annotation
                  atSign: @ @29
                  expression: UnqualifiedNameExpression
                    name: foo @30
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @30
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F4
      getters
        #F4 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F3
  mixins
    isSimplyBounded mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      metadata
        annotation_0
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            annotation_1
      superclassConstraints
        Object
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onTypeAlias_classic() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
typedef void F<@foo T>(@foo int a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:34) (firstTokenOffset:16) (offset:34)
          element: <testLibrary>::@typeAlias::F
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: foo @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          typeParameters
            #F2 T (nameOffset:41) (firstTokenOffset:36) (offset:41)
              element: #E0 T
              metadata
                annotation_1: Annotation
                  atSign: @ @36
                  expression: UnqualifiedNameExpression
                    name: foo @37
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @37
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F4
      getters
        #F4 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F3
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      metadata
        annotation_0
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            annotation_1
      aliasedType: void Function(int)
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onTypeAlias_genericFunctionType() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
typedef A<@foo T> = void Function<@foo U>(@foo int a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@typeAlias::A
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: foo @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          typeParameters
            #F2 T (nameOffset:36) (firstTokenOffset:31) (offset:36)
              element: #E0 T
              metadata
                annotation_1: Annotation
                  atSign: @ @31
                  expression: UnqualifiedNameExpression
                    name: foo @32
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @32
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F4
      getters
        #F4 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F3
  typeAliases
    isSimplyBounded A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      metadata
        annotation_0
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            annotation_1
      aliasedType: void Function<U>(int)
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onUnit() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of my.lib;
''');

    var library = await buildLibrary(r'''
library my.lib;

@foo
part 'a.dart';

@foo
part 'b.dart';

const foo = 0;
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
          partKeywordOffset: 22
          metadata
            annotation_0: Annotation
              atSign: @ @17
              expression: UnqualifiedNameExpression
                name: foo @18
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @18
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          unit: #F1
        part_1
          uri: package:test/b.dart
          partKeywordOffset: 43
          metadata
            annotation_1: Annotation
              atSign: @ @38
              expression: UnqualifiedNameExpression
                name: foo @39
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @39
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          unit: #F2
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:65) (firstTokenOffset:65) (offset:65)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @71
              staticType: int
          inducedGetter: #F4
      getters
        #F4 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F3
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F2
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F1
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_offsets_onUnitFunction() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
void f<@foo T>({@foo int? a = 42}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F1
      functions
        #F3 isComplete isOriginDeclaration isStatic f (nameOffset:26) (firstTokenOffset:16) (offset:26)
          element: <testLibrary>::@function::f
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: foo @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          typeParameters
            #F4 T (nameOffset:33) (firstTokenOffset:28) (offset:33)
              element: #E0 T
              metadata
                annotation_1: Annotation
                  atSign: @ @28
                  expression: UnqualifiedNameExpression
                    name: foo @29
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
          formalParameters
            #F5 optionalNamed isOriginDeclaration a (nameOffset:47) (firstTokenOffset:37) (offset:47)
              element: <testLibrary>::@function::f::@formalParameter::a
              metadata
                annotation_2: Annotation
                  atSign: @ @37
                  expression: UnqualifiedNameExpression
                    name: foo @38
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @38
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
              constantInitializer2: expression_1
                IntegerLiteral
                  literal: 42 @51
                  staticType: int
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      metadata
        annotation_0
      typeParameters
        #E0 T
          firstFragment: #F4
          metadata
            annotation_1
      formalParameters
        #E1 optionalNamed hasDefaultValue a
          firstFragment: #F5
          type: int?
          metadata
            annotation_2
          constantInitializer2: expression_1
      returnType: void
''');
  }

  test_metadata_offsets_onUnitGetter() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
int get getter => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F2
        #F3 isOriginGetterSetter isStatic getter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@topLevelVariable::getter
      getters
        #F2 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F1
        #F4 isComplete isOriginDeclaration isStatic getter (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@getter::getter
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: foo @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
    isOriginGetterSetter isStatic getter
      reference: <testLibrary>::@topLevelVariable::getter
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::getter
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
    isOriginDeclaration isStatic getter
      reference: <testLibrary>::@getter::getter
      firstFragment: #F4
      metadata
        annotation_0
      returnType: int
      variable: <testLibrary>::@topLevelVariable::getter
''');
  }

  test_metadata_offsets_onUnitSetter() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
set setter(@foo int a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F2
        #F3 isOriginGetterSetter isStatic setter (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@topLevelVariable::setter
      getters
        #F2 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F1
      setters
        #F4 hasImplicitReturnType isComplete isOriginDeclaration isStatic setter (nameOffset:25) (firstTokenOffset:16) (offset:25)
          element: <testLibrary>::@setter::setter
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: foo @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          formalParameters
            #F5 requiredPositional isOriginDeclaration a (nameOffset:41) (firstTokenOffset:32) (offset:41)
              element: <testLibrary>::@setter::setter::@formalParameter::a
              metadata
                annotation_1: Annotation
                  atSign: @ @32
                  expression: UnqualifiedNameExpression
                    name: foo @33
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @33
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
    isOriginGetterSetter isStatic setter
      reference: <testLibrary>::@topLevelVariable::setter
      firstFragment: #F3
      type: int
      setter: <testLibrary>::@setter::setter
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    hasImplicitReturnType isOriginDeclaration isStatic setter
      reference: <testLibrary>::@setter::setter
      firstFragment: #F4
      metadata
        annotation_0
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F5
          type: int
          metadata
            annotation_1
      returnType: void
      variable: <testLibrary>::@topLevelVariable::setter
''');
  }

  test_metadata_offsets_onUnitVariable() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
var isNotConst = 1;

@foo
const isConst = 2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F2
        #F3 hasImplicitType hasInitializer isOriginDeclaration isStatic isNotConst (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::isNotConst
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: foo @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @17
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          inducedGetter: #F4
          inducedSetter: #F5
        #F6 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isConst (nameOffset:53) (firstTokenOffset:53) (offset:53)
          element: <testLibrary>::@topLevelVariable::isConst
          metadata
            annotation_1: Annotation
              atSign: @ @42
              expression: UnqualifiedNameExpression
                name: foo @43
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::foo
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: foo @43
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 2 @63
              staticType: int
          inducedGetter: #F7
      getters
        #F2 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F1
        #F4 isComplete isOriginVariable isStatic isNotConst (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::isNotConst
          inducingVariable: #F3
        #F7 isComplete isOriginVariable isStatic isConst (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@getter::isConst
          inducingVariable: #F6
      setters
        #F5 isComplete isOriginVariable isStatic isNotConst (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::isNotConst
          inducingVariable: #F3
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::isNotConst::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::foo
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer isNotConst
      reference: <testLibrary>::@topLevelVariable::isNotConst
      firstFragment: #F3
      metadata
        annotation_0
      type: int
      getter: <testLibrary>::@getter::isNotConst
      setter: <testLibrary>::@setter::isNotConst
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer isConst
      reference: <testLibrary>::@topLevelVariable::isConst
      firstFragment: #F6
      metadata
        annotation_1
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::isConst
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
    isOriginVariable isStatic isNotConst
      reference: <testLibrary>::@getter::isNotConst
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::isNotConst
    isOriginVariable isStatic isConst
      reference: <testLibrary>::@getter::isConst
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::isConst
  setters
    isOriginVariable isStatic isNotConst
      reference: <testLibrary>::@setter::isNotConst
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::isNotConst
''');
  }

  test_metadata_partDirective() async {
    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
@a
part 'foo.dart';

const a = 0;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    annotation_0: Annotation
      atSign: @ @0
      expression: UnqualifiedNameExpression
        name: a @1
        resolution: GetterInvocationResolution
          element: <testLibrary>::@getter::a
          type: int
        staticType: int
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/foo.dart
          partKeywordOffset: 3
          metadata
            annotation_1: Annotation
              atSign: @ @0
              expression: UnqualifiedNameExpression
                name: a @1
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: a @1
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          unit: #F1
      topLevelVariables
        #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:27) (firstTokenOffset:27) (offset:27)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @31
              staticType: int
          inducedGetter: #F3
      getters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@getter::a
          inducingVariable: #F2
    #F1 package:test/foo.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_partDirective2() async {
    newFile('$testPackageLibPath/foo.dart', r'''
part of L;
''');
    var library = await buildLibrary(r'''
library L;

@a
part 'foo.dart';

const a = null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: L
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/foo.dart
          partKeywordOffset: 15
          metadata
            annotation_0: Annotation
              atSign: @ @12
              expression: UnqualifiedNameExpression
                name: a @13
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: a @13
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          unit: #F1
      topLevelVariables
        #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:39) (firstTokenOffset:39) (offset:39)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @43
              staticType: Null
          inducedGetter: #F3
      getters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@getter::a
          inducingVariable: #F2
    #F1 package:test/foo.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_partDirective3() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');
    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');
    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
''');

    // The difference with the test above is that we ask the part first.
    // There was a bug that we were not loading library directives.
    expect(library.firstFragment.parts[0].metadata.annotations, isEmpty);
  }

  test_metadata_partDirective_afterAnnotatedLibraryDirective() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
@a
library;
@b
part 'a.dart';

const a = 0;
const b = 1;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    annotation_0: Annotation
      atSign: @ @0
      expression: UnqualifiedNameExpression
        name: a @1
        resolution: GetterInvocationResolution
          element: <testLibrary>::@getter::a
          type: int
        staticType: int
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 15
          metadata
            annotation_1: Annotation
              atSign: @ @12
              expression: UnqualifiedNameExpression
                name: b @13
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::b
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: b @13
                element: <testLibrary>::@getter::b
                staticType: null
              element: <testLibrary>::@getter::b
          unit: #F1
      topLevelVariables
        #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @41
              staticType: int
          inducedGetter: #F3
        #F4 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:50) (firstTokenOffset:50) (offset:50)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 1 @54
              staticType: int
          inducedGetter: #F5
      getters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::a
          inducingVariable: #F2
        #F5 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@getter::b
          inducingVariable: #F4
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_partOf_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
@deprecated
class A {}
''');
    var library = await buildLibrary(r'''
part 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F2 class A (nameOffset:39) (firstTokenOffset:21) (offset:39)
          element: <testLibrary>::@class::A
          metadata
            annotation_0: Annotation
              atSign: @ @21
              expression: UnqualifiedNameExpression
                name: deprecated @22
                resolution: GetterInvocationResolution
                  element: dart:core::@getter::deprecated
                  type: Deprecated
                staticType: Deprecated
              name: SimpleIdentifier
                token: deprecated @22
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F2
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
''');
  }

  test_metadata_partOf_exportLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
@deprecated
export 'dart:math';
''');
    var library = await buildLibrary(r'''
part 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      libraryExports
        dart:math
          metadata
            annotation_0: Annotation
              atSign: @ @21
              expression: UnqualifiedNameExpression
                name: deprecated @22
                resolution: GetterInvocationResolution
                  element: dart:core::@getter::deprecated
                  type: Deprecated
                staticType: Deprecated
              name: SimpleIdentifier
                token: deprecated @22
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
''');
  }

  test_metadata_partOf_importLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
@deprecated
import 'dart:math';
''');
    var library = await buildLibrary(r'''
part 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      libraryImports
        dart:math
          metadata
            annotation_0: Annotation
              atSign: @ @21
              expression: UnqualifiedNameExpression
                name: deprecated @22
                resolution: GetterInvocationResolution
                  element: dart:core::@getter::deprecated
                  type: Deprecated
                staticType: Deprecated
              name: SimpleIdentifier
                token: deprecated @22
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
''');
  }

  test_metadata_partOf_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
@deprecated
part 'a.dart';
''');

    var library = await buildLibrary(r'''
part 'b.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/b.dart
          partKeywordOffset: 0
          unit: #F1
    #F1 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F2
      parts
        part_1
          uri: package:test/a.dart
          partKeywordOffset: 33
          metadata
            annotation_0: Annotation
              atSign: @ @21
              expression: UnqualifiedNameExpression
                name: deprecated @22
                resolution: GetterInvocationResolution
                  element: dart:core::@getter::deprecated
                  type: Deprecated
                staticType: Deprecated
              name: SimpleIdentifier
                token: deprecated @22
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          unit: #F2
    #F2 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F1
''');
  }

  test_metadata_prefixed_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
const b = null;
''');
    var library = await buildLibrary(r'''
import "a.dart" as a;

@a.b
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as a (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix::a
          fragments: @19
      classes
        #F1 class C (nameOffset:34) (firstTokenOffset:23) (offset:34)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @23
              expression: ImportPrefixedNameExpression
                importPrefix: ImportPrefixReference
                  name: a @24
                  period: . @25
                  element: <testLibraryFragment>::@prefix::a
                name: b @26
                resolution: GetterInvocationResolution
                  element: package:test/a.dart::@getter::b
                  type: dynamic
                staticType: dynamic
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: a @24
                  element: <testLibraryFragment>::@prefix::a
                  staticType: null
                period: . @25
                identifier: SimpleIdentifier
                  token: b @26
                  element: package:test/a.dart::@getter::b
                  staticType: null
                element: package:test/a.dart::@getter::b
                staticType: null
              element: package:test/a.dart::@getter::b
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_metadata_simpleFormalParameter() async {
    var library = await buildLibrary(r'''
const a = null;
f(@a x) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
      functions
        #F3 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@function::f
          formalParameters
            #F4 requiredPositional hasImplicitType isOriginDeclaration x (nameOffset:21) (firstTokenOffset:18) (offset:21)
              element: <testLibrary>::@function::f::@formalParameter::x
              metadata
                annotation_0: Annotation
                  atSign: @ @18
                  expression: UnqualifiedNameExpression
                    name: a @19
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @19
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    hasImplicitReturnType isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional hasImplicitType x
          firstFragment: #F4
          type: dynamic
          metadata
            annotation_0
      returnType: dynamic
''');
  }

  test_metadata_simpleFormalParameter_augmentation_constructor_inAugmentation_first() async {
    var library = await buildLibrary(r'''
const a = 0;

class A {
  A(int x);
}

augment class A {
  augment A(@a int x);
}
''');
    // Check metadata without asking any other properties.
    var x = library.getClass('A')!.unnamedConstructor!.formalParameters.single;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @69
        expression: UnqualifiedNameExpression
          name: a @70
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @70
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
  fragments
    #F0
    #F1
      metadata
        annotation_0
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F3 class A (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::A
          nextFragment: #F4
          constructors
            #F5 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 26
              formalParameters
                #F0 requiredPositional isOriginDeclaration x (nameOffset:32) (firstTokenOffset:28) (offset:32)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
                  nextFragment: #F1
              nextFragment: #F6
        #F4 isAugmentation class A (nameOffset:53) (firstTokenOffset:39) (offset:53)
          element: <testLibrary>::@class::A
          previousFragment: #F3
          constructors
            #F6 isAugmentation isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:59) (offset:67)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 67
              formalParameters
                #F1 requiredPositional isOriginDeclaration x (nameOffset:76) (firstTokenOffset:69) (offset:76)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
                  metadata
                    annotation_0
                  previousFragment: #F0
              previousFragment: #F5
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F8
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F0
              type: int
              metadata
                annotation_0
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_simpleFormalParameter_augmentation_constructor_inAugmentation_missingInIntroductory() async {
    var library = await buildLibrary(r'''
const a = 0;

class A {
  A();
}

augment class A {
  augment A([@a int? x]);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          constructors
            #F3 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 26
              formalParameters
                #F4 optionalPositional isOriginOtherFragmentOfEnclosing x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
                  nextFragment: #F5
              nextFragment: #F6
        #F2 isAugmentation class A (nameOffset:48) (firstTokenOffset:34) (offset:48)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          constructors
            #F6 isAugmentation isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:54) (offset:62)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 62
              formalParameters
                #F5 optionalPositional isOriginDeclaration x (nameOffset:73) (firstTokenOffset:65) (offset:73)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
                  metadata
                    annotation_0: Annotation
                      atSign: @ @65
                      expression: UnqualifiedNameExpression
                        name: a @66
                        resolution: GetterInvocationResolution
                          element: <testLibrary>::@getter::a
                          type: int
                        staticType: int
                      name: SimpleIdentifier
                        token: a @66
                        element: <testLibrary>::@getter::a
                        staticType: null
                      element: <testLibrary>::@getter::a
                  previousFragment: #F4
              previousFragment: #F3
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F8
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_simpleFormalParameter_augmentation_constructor_inBoth_first() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = 0;

class A {
  A(@a int x);
}

augment class A {
  augment A(@b int x);
}
''');
    // Check metadata without asking any other properties.
    var x = library.getClass('A')!.unnamedConstructor!.formalParameters.single;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @41
        expression: UnqualifiedNameExpression
          name: a @42
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @42
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
      annotation_1: Annotation
        atSign: @ @85
        expression: UnqualifiedNameExpression
          name: b @86
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::b
            type: int
          staticType: int
        name: SimpleIdentifier
          token: b @86
          element: <testLibrary>::@getter::b
          staticType: null
        element: <testLibrary>::@getter::b
  fragments
    #F0
      metadata
        annotation_0
    #F1
      metadata
        annotation_1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F3 class A (nameOffset:33) (firstTokenOffset:27) (offset:33)
          element: <testLibrary>::@class::A
          nextFragment: #F4
          constructors
            #F5 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:39) (offset:39)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 39
              formalParameters
                #F0 requiredPositional isOriginDeclaration x (nameOffset:48) (firstTokenOffset:41) (offset:48)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
                  metadata
                    annotation_0
                  nextFragment: #F1
              nextFragment: #F6
        #F4 isAugmentation class A (nameOffset:69) (firstTokenOffset:55) (offset:69)
          element: <testLibrary>::@class::A
          previousFragment: #F3
          constructors
            #F6 isAugmentation isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:75) (offset:83)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 83
              formalParameters
                #F1 requiredPositional isOriginDeclaration x (nameOffset:92) (firstTokenOffset:85) (offset:92)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
                  metadata
                    annotation_1
                  previousFragment: #F0
              previousFragment: #F5
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F8
        #F9 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 0 @23
              staticType: int
          inducedGetter: #F10
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
        #F10 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F9
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F0
              type: int
              metadata
                annotation_0
                annotation_1
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F9
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_simpleFormalParameter_augmentation_constructor_inIntroductory_first() async {
    var library = await buildLibrary(r'''
const a = 0;

class A {
  A(@a int x);
}

augment class A {
  augment A(int x);
}
''');
    // Check metadata without asking any other properties, reaching
    // the element via the augmentation, so the introductory fragment is not
    // read.
    var constructor = library.getClass('A')!.unnamedConstructor!;
    var x = constructor.fragments.last.formalParameters.single.element;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @28
        expression: UnqualifiedNameExpression
          name: a @29
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @29
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
  fragments
    #F0
      metadata
        annotation_0
    #F1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F3 class A (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::A
          nextFragment: #F4
          constructors
            #F5 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 26
              formalParameters
                #F0 requiredPositional isOriginDeclaration x (nameOffset:35) (firstTokenOffset:28) (offset:35)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
                  metadata
                    annotation_0
                  nextFragment: #F1
              nextFragment: #F6
        #F4 isAugmentation class A (nameOffset:56) (firstTokenOffset:42) (offset:56)
          element: <testLibrary>::@class::A
          previousFragment: #F3
          constructors
            #F6 isAugmentation isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:62) (offset:70)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 70
              formalParameters
                #F1 requiredPositional isOriginDeclaration x (nameOffset:76) (firstTokenOffset:72) (offset:76)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
                  previousFragment: #F0
              previousFragment: #F5
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F8
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F0
              type: int
              metadata
                annotation_0
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_simpleFormalParameter_augmentation_getter_inAugmentation_first() async {
    var library = await buildLibrary(r'''
const a = 0;

int get foo(int x);

augment int get foo(@a int x) => 0;
''');
    // Check metadata without asking any other properties.
    var x = library.getGetter('foo')!.formalParameters.single;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: x@30
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @55
        expression: UnqualifiedNameExpression
          name: a @56
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @56
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
  fragments
    #F0
    #F1
      metadata
        annotation_0
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F4
        #F5 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
        #F6 isOriginDeclaration isStatic foo (nameOffset:22) (firstTokenOffset:14) (offset:22)
          element: <testLibrary>::@getter::foo
          formalParameters
            #F0 requiredPositional isOriginDeclaration x (nameOffset:30) (firstTokenOffset:26) (offset:30)
              element: x@30
              nextFragment: #F1
          nextFragment: #F7
        #F7 isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:51) (firstTokenOffset:35) (offset:51)
          element: <testLibrary>::@getter::foo
          formalParameters
            #F1 requiredPositional isOriginDeclaration x (nameOffset:62) (firstTokenOffset:55) (offset:62)
              element: x@30
              metadata
                annotation_0
              previousFragment: #F0
          previousFragment: #F6
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    isOriginGetterSetter isStatic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F5
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F6
      formalParameters
        #E0 requiredPositional x
          firstFragment: #F0
          type: int
          metadata
            annotation_0
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_simpleFormalParameter_augmentation_getter_inAugmentation_missingInIntroductory() async {
    var library = await buildLibrary(r'''
const a = 0;

int get foo => 0;

augment int get foo([@a int? x]) => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F2
        #F3 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F4 isComplete isOriginDeclaration isStatic foo (nameOffset:22) (firstTokenOffset:14) (offset:22)
          element: <testLibrary>::@getter::foo
          formalParameters
            #F5 optionalPositional isOriginOtherFragmentOfEnclosing x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: x@null
              nextFragment: #F6
          nextFragment: #F7
        #F7 isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:49) (firstTokenOffset:33) (offset:49)
          element: <testLibrary>::@getter::foo
          formalParameters
            #F6 optionalPositional isOriginDeclaration x (nameOffset:62) (firstTokenOffset:54) (offset:62)
              element: x@null
              metadata
                annotation_0: Annotation
                  atSign: @ @54
                  expression: UnqualifiedNameExpression
                    name: a @55
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: a @55
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
              previousFragment: #F5
          previousFragment: #F4
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    isOriginGetterSetter isStatic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_simpleFormalParameter_augmentation_getter_inBoth_first() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = 0;

int get foo(@a int x);

augment int get foo(@b int x) => 0;
''');
    // Check metadata without asking any other properties.
    var x = library.getGetter('foo')!.formalParameters.single;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: x@46
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @39
        expression: UnqualifiedNameExpression
          name: a @40
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @40
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
      annotation_1: Annotation
        atSign: @ @71
        expression: UnqualifiedNameExpression
          name: b @72
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::b
            type: int
          staticType: int
        name: SimpleIdentifier
          token: b @72
          element: <testLibrary>::@getter::b
          staticType: null
        element: <testLibrary>::@getter::b
  fragments
    #F0
      metadata
        annotation_0
    #F1
      metadata
        annotation_1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F4
        #F5 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 0 @23
              staticType: int
          inducedGetter: #F6
        #F7 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
        #F6 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F5
        #F8 isOriginDeclaration isStatic foo (nameOffset:35) (firstTokenOffset:27) (offset:35)
          element: <testLibrary>::@getter::foo
          formalParameters
            #F0 requiredPositional isOriginDeclaration x (nameOffset:46) (firstTokenOffset:39) (offset:46)
              element: x@46
              metadata
                annotation_0
              nextFragment: #F1
          nextFragment: #F9
        #F9 isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:67) (firstTokenOffset:51) (offset:67)
          element: <testLibrary>::@getter::foo
          formalParameters
            #F1 requiredPositional isOriginDeclaration x (nameOffset:78) (firstTokenOffset:71) (offset:78)
              element: x@46
              metadata
                annotation_1
              previousFragment: #F0
          previousFragment: #F8
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F5
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
    isOriginGetterSetter isStatic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F8
      formalParameters
        #E0 requiredPositional x
          firstFragment: #F0
          type: int
          metadata
            annotation_0
            annotation_1
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_simpleFormalParameter_augmentation_getter_inIntroductory_first() async {
    var library = await buildLibrary(r'''
const a = 0;

int get foo(@a int x);

augment int get foo(int x) => 0;
''');
    // Check metadata without asking any other properties, reaching
    // the element via the augmentation, so the introductory fragment is not
    // read.
    var foo = library.getGetter('foo')!;
    var x = foo.fragments.last.formalParameters.single.element;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: x@33
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @26
        expression: UnqualifiedNameExpression
          name: a @27
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @27
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
  fragments
    #F0
      metadata
        annotation_0
    #F1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F4
        #F5 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
        #F6 isOriginDeclaration isStatic foo (nameOffset:22) (firstTokenOffset:14) (offset:22)
          element: <testLibrary>::@getter::foo
          formalParameters
            #F0 requiredPositional isOriginDeclaration x (nameOffset:33) (firstTokenOffset:26) (offset:33)
              element: x@33
              metadata
                annotation_0
              nextFragment: #F1
          nextFragment: #F7
        #F7 isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:54) (firstTokenOffset:38) (offset:54)
          element: <testLibrary>::@getter::foo
          formalParameters
            #F1 requiredPositional isOriginDeclaration x (nameOffset:62) (firstTokenOffset:58) (offset:62)
              element: x@33
              previousFragment: #F0
          previousFragment: #F6
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    isOriginGetterSetter isStatic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F5
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F6
      formalParameters
        #E0 requiredPositional x
          firstFragment: #F0
          type: int
          metadata
            annotation_0
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_simpleFormalParameter_augmentation_method_inAugmentation_first() async {
    var library = await buildLibrary(r'''
const a = 0;

class A {
  void foo(int x);
}

augment class A {
  augment void foo(@a int x) {}
}
''');
    // Check metadata without asking any other properties.
    var x = library.getClass('A')!.getMethod('foo')!.formalParameters.single;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @83
        expression: UnqualifiedNameExpression
          name: a @84
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @84
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
  fragments
    #F0
    #F1
      metadata
        annotation_0
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F3 class A (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::A
          nextFragment: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F6 isAbstract isOriginDeclaration foo (nameOffset:31) (firstTokenOffset:26) (offset:31)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F7
              formalParameters
                #F0 requiredPositional isOriginDeclaration x (nameOffset:39) (firstTokenOffset:35) (offset:39)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
                  nextFragment: #F1
        #F4 isAugmentation class A (nameOffset:60) (firstTokenOffset:46) (offset:60)
          element: <testLibrary>::@class::A
          previousFragment: #F3
          methods
            #F7 isAugmentation isComplete isOriginDeclaration foo (nameOffset:79) (firstTokenOffset:66) (offset:79)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F6
              formalParameters
                #F1 requiredPositional isOriginDeclaration x (nameOffset:90) (firstTokenOffset:83) (offset:90)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
                  metadata
                    annotation_0
                  previousFragment: #F0
      topLevelVariables
        #F8 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F9
      getters
        #F9 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F8
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F0
              type: int
              metadata
                annotation_0
          returnType: void
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_simpleFormalParameter_augmentation_method_inAugmentation_missingInIntroductory() async {
    var library = await buildLibrary(r'''
const a = 0;

class A {
  void foo() {}
}

augment class A {
  augment void foo([@a int? x]) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::A
          nextFragment: #F2
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 isComplete isOriginDeclaration foo (nameOffset:31) (firstTokenOffset:26) (offset:31)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F5
              formalParameters
                #F6 optionalPositional isOriginOtherFragmentOfEnclosing x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
                  nextFragment: #F7
        #F2 isAugmentation class A (nameOffset:57) (firstTokenOffset:43) (offset:57)
          element: <testLibrary>::@class::A
          previousFragment: #F1
          methods
            #F5 isAugmentation isComplete isOriginDeclaration foo (nameOffset:76) (firstTokenOffset:63) (offset:76)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F4
              formalParameters
                #F7 optionalPositional isOriginDeclaration x (nameOffset:89) (firstTokenOffset:81) (offset:89)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
                  metadata
                    annotation_0: Annotation
                      atSign: @ @81
                      expression: UnqualifiedNameExpression
                        name: a @82
                        resolution: GetterInvocationResolution
                          element: <testLibrary>::@getter::a
                          type: int
                        staticType: int
                      name: SimpleIdentifier
                        token: a @82
                        element: <testLibrary>::@getter::a
                        staticType: null
                      element: <testLibrary>::@getter::a
                  previousFragment: #F6
      topLevelVariables
        #F8 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F9
      getters
        #F9 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F8
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F4
          returnType: void
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_simpleFormalParameter_augmentation_method_inBoth_first() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = 0;

class A {
  void foo(@a int x);
}

augment class A {
  augment void foo(@b int x) {}
}
''');
    // Check metadata without asking any other properties.
    var x = library.getClass('A')!.getMethod('foo')!.formalParameters.single;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @48
        expression: UnqualifiedNameExpression
          name: a @49
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @49
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
      annotation_1: Annotation
        atSign: @ @99
        expression: UnqualifiedNameExpression
          name: b @100
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::b
            type: int
          staticType: int
        name: SimpleIdentifier
          token: b @100
          element: <testLibrary>::@getter::b
          staticType: null
        element: <testLibrary>::@getter::b
  fragments
    #F0
      metadata
        annotation_0
    #F1
      metadata
        annotation_1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F3 class A (nameOffset:33) (firstTokenOffset:27) (offset:33)
          element: <testLibrary>::@class::A
          nextFragment: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F6 isAbstract isOriginDeclaration foo (nameOffset:44) (firstTokenOffset:39) (offset:44)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F7
              formalParameters
                #F0 requiredPositional isOriginDeclaration x (nameOffset:55) (firstTokenOffset:48) (offset:55)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
                  metadata
                    annotation_0
                  nextFragment: #F1
        #F4 isAugmentation class A (nameOffset:76) (firstTokenOffset:62) (offset:76)
          element: <testLibrary>::@class::A
          previousFragment: #F3
          methods
            #F7 isAugmentation isComplete isOriginDeclaration foo (nameOffset:95) (firstTokenOffset:82) (offset:95)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F6
              formalParameters
                #F1 requiredPositional isOriginDeclaration x (nameOffset:106) (firstTokenOffset:99) (offset:106)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
                  metadata
                    annotation_1
                  previousFragment: #F0
      topLevelVariables
        #F8 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F9
        #F10 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 0 @23
              staticType: int
          inducedGetter: #F11
      getters
        #F9 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F8
        #F11 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F10
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F0
              type: int
              metadata
                annotation_0
                annotation_1
          returnType: void
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F10
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_metadata_simpleFormalParameter_augmentation_method_inIntroductory_first() async {
    var library = await buildLibrary(r'''
const a = 0;

class A {
  void foo(@a int x);
}

augment class A {
  augment void foo(int x) {}
}
''');
    // Check metadata without asking any other properties, reaching
    // the element via the augmentation, so the introductory fragment is not
    // read.
    var foo = library.getClass('A')!.getMethod('foo')!;
    var x = foo.fragments.last.formalParameters.single.element;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @35
        expression: UnqualifiedNameExpression
          name: a @36
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @36
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
  fragments
    #F0
      metadata
        annotation_0
    #F1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F3 class A (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::A
          nextFragment: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F6 isAbstract isOriginDeclaration foo (nameOffset:31) (firstTokenOffset:26) (offset:31)
              element: <testLibrary>::@class::A::@method::foo
              nextFragment: #F7
              formalParameters
                #F0 requiredPositional isOriginDeclaration x (nameOffset:42) (firstTokenOffset:35) (offset:42)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
                  metadata
                    annotation_0
                  nextFragment: #F1
        #F4 isAugmentation class A (nameOffset:63) (firstTokenOffset:49) (offset:63)
          element: <testLibrary>::@class::A
          previousFragment: #F3
          methods
            #F7 isAugmentation isComplete isOriginDeclaration foo (nameOffset:82) (firstTokenOffset:69) (offset:82)
              element: <testLibrary>::@class::A::@method::foo
              previousFragment: #F6
              formalParameters
                #F1 requiredPositional isOriginDeclaration x (nameOffset:90) (firstTokenOffset:86) (offset:90)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
                  previousFragment: #F0
      topLevelVariables
        #F8 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F9
      getters
        #F9 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F8
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F0
              type: int
              metadata
                annotation_0
          returnType: void
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_simpleFormalParameter_augmentation_setter_inAugmentation_first() async {
    var library = await buildLibrary(r'''
const a = 0;

set foo(int x);

augment set foo(@a int x) {}
''');
    // Check metadata without asking any other properties.
    var x = library.getSetter('foo')!.formalParameters.single;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@setter::foo::@formalParameter::x
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @47
        expression: UnqualifiedNameExpression
          name: a @48
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @48
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
  fragments
    #F0
    #F1
      metadata
        annotation_0
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F4
        #F5 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
      setters
        #F6 hasImplicitReturnType isOriginDeclaration isStatic foo (nameOffset:18) (firstTokenOffset:14) (offset:18)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F0 requiredPositional isOriginDeclaration x (nameOffset:26) (firstTokenOffset:22) (offset:26)
              element: <testLibrary>::@setter::foo::@formalParameter::x
              nextFragment: #F1
          nextFragment: #F7
        #F7 hasImplicitReturnType isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:43) (firstTokenOffset:31) (offset:43)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F1 requiredPositional isOriginDeclaration x (nameOffset:54) (firstTokenOffset:47) (offset:54)
              element: <testLibrary>::@setter::foo::@formalParameter::x
              metadata
                annotation_0
              previousFragment: #F0
          previousFragment: #F6
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    isOriginGetterSetter isStatic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F5
      type: int
      setter: <testLibrary>::@setter::foo
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
  setters
    hasImplicitReturnType isOriginDeclaration isStatic foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F6
      formalParameters
        #E0 requiredPositional x
          firstFragment: #F0
          type: int
          metadata
            annotation_0
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_simpleFormalParameter_augmentation_setter_inBoth_first() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = 0;

set foo(@a int x);

augment set foo(@b int x) {}
''');
    // Check metadata without asking any other properties.
    var x = library.getSetter('foo')!.formalParameters.single;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@setter::foo::@formalParameter::x
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @35
        expression: UnqualifiedNameExpression
          name: a @36
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @36
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
      annotation_1: Annotation
        atSign: @ @63
        expression: UnqualifiedNameExpression
          name: b @64
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::b
            type: int
          staticType: int
        name: SimpleIdentifier
          token: b @64
          element: <testLibrary>::@getter::b
          staticType: null
        element: <testLibrary>::@getter::b
  fragments
    #F0
      metadata
        annotation_0
    #F1
      metadata
        annotation_1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F4
        #F5 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 0 @23
              staticType: int
          inducedGetter: #F6
        #F7 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
        #F6 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F5
      setters
        #F8 hasImplicitReturnType isOriginDeclaration isStatic foo (nameOffset:31) (firstTokenOffset:27) (offset:31)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F0 requiredPositional isOriginDeclaration x (nameOffset:42) (firstTokenOffset:35) (offset:42)
              element: <testLibrary>::@setter::foo::@formalParameter::x
              metadata
                annotation_0
              nextFragment: #F1
          nextFragment: #F9
        #F9 hasImplicitReturnType isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:59) (firstTokenOffset:47) (offset:59)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F1 requiredPositional isOriginDeclaration x (nameOffset:70) (firstTokenOffset:63) (offset:70)
              element: <testLibrary>::@setter::foo::@formalParameter::x
              metadata
                annotation_1
              previousFragment: #F0
          previousFragment: #F8
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F5
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
    isOriginGetterSetter isStatic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F7
      type: int
      setter: <testLibrary>::@setter::foo
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
  setters
    hasImplicitReturnType isOriginDeclaration isStatic foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F8
      formalParameters
        #E0 requiredPositional x
          firstFragment: #F0
          type: int
          metadata
            annotation_0
            annotation_1
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_simpleFormalParameter_augmentation_setter_inIntroductory_first() async {
    var library = await buildLibrary(r'''
const a = 0;

set foo(@a int x);

augment set foo(int x) {}
''');
    // Check metadata without asking any other properties, reaching
    // the element via the augmentation, so the introductory fragment is not
    // read.
    var foo = library.getSetter('foo')!;
    var x = foo.fragments.last.formalParameters.single.element;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@setter::foo::@formalParameter::x
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @22
        expression: UnqualifiedNameExpression
          name: a @23
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @23
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
  fragments
    #F0
      metadata
        annotation_0
    #F1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F4
        #F5 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
      setters
        #F6 hasImplicitReturnType isOriginDeclaration isStatic foo (nameOffset:18) (firstTokenOffset:14) (offset:18)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F0 requiredPositional isOriginDeclaration x (nameOffset:29) (firstTokenOffset:22) (offset:29)
              element: <testLibrary>::@setter::foo::@formalParameter::x
              metadata
                annotation_0
              nextFragment: #F1
          nextFragment: #F7
        #F7 hasImplicitReturnType isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:46) (firstTokenOffset:34) (offset:46)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F1 requiredPositional isOriginDeclaration x (nameOffset:54) (firstTokenOffset:50) (offset:54)
              element: <testLibrary>::@setter::foo::@formalParameter::x
              previousFragment: #F0
          previousFragment: #F6
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    isOriginGetterSetter isStatic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F5
      type: int
      setter: <testLibrary>::@setter::foo
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
  setters
    hasImplicitReturnType isOriginDeclaration isStatic foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F6
      formalParameters
        #E0 requiredPositional x
          firstFragment: #F0
          type: int
          metadata
            annotation_0
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_simpleFormalParameter_augmentation_topLevelFunction_inAugmentation_first() async {
    var library = await buildLibrary(r'''
const a = null;

void foo(int x);

augment void foo(@a int x) {}
''');
    // Check metadata without asking any other properties.
    var x = library.getTopLevelFunction('foo')!.formalParameters.single;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@function::foo::@formalParameter::x
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @52
        expression: UnqualifiedNameExpression
          name: a @53
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: dynamic
          staticType: dynamic
        name: SimpleIdentifier
          token: a @53
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
  fragments
    #F0
    #F1
      metadata
        annotation_0
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F4
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
      functions
        #F5 isOriginDeclaration isStatic foo (nameOffset:22) (firstTokenOffset:17) (offset:22)
          element: <testLibrary>::@function::foo
          nextFragment: #F6
          formalParameters
            #F0 requiredPositional isOriginDeclaration x (nameOffset:30) (firstTokenOffset:26) (offset:30)
              element: <testLibrary>::@function::foo::@formalParameter::x
              nextFragment: #F1
        #F6 isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:48) (firstTokenOffset:35) (offset:48)
          element: <testLibrary>::@function::foo
          previousFragment: #F5
          formalParameters
            #F1 requiredPositional isOriginDeclaration x (nameOffset:59) (firstTokenOffset:52) (offset:59)
              element: <testLibrary>::@function::foo::@formalParameter::x
              metadata
                annotation_0
              previousFragment: #F0
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional x
          firstFragment: #F0
          type: int
          metadata
            annotation_0
      returnType: void
''');
  }

  test_metadata_simpleFormalParameter_augmentation_topLevelFunction_inAugmentation_missingInIntroductory() async {
    var library = await buildLibrary(r'''
const a = 0;

void foo() {}

augment void foo([@a int? x]) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
      functions
        #F3 isComplete isOriginDeclaration isStatic foo (nameOffset:19) (firstTokenOffset:14) (offset:19)
          element: <testLibrary>::@function::foo
          nextFragment: #F4
          formalParameters
            #F5 optionalPositional isOriginOtherFragmentOfEnclosing x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@function::foo::@formalParameter::x
              nextFragment: #F6
        #F4 isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:42) (firstTokenOffset:29) (offset:42)
          element: <testLibrary>::@function::foo
          previousFragment: #F3
          formalParameters
            #F6 optionalPositional isOriginDeclaration x (nameOffset:55) (firstTokenOffset:47) (offset:55)
              element: <testLibrary>::@function::foo::@formalParameter::x
              metadata
                annotation_0: Annotation
                  atSign: @ @47
                  expression: UnqualifiedNameExpression
                    name: a @48
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: a @48
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
              previousFragment: #F5
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
  functions
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F3
      returnType: void
''');
  }

  test_metadata_simpleFormalParameter_augmentation_topLevelFunction_inBoth_first() async {
    var library = await buildLibrary(r'''
const a = 0;
const b = 0;

void foo(@a int x);

augment void foo(@b int x) {}
''');
    // Check metadata without asking any other properties.
    var x = library.getTopLevelFunction('foo')!.formalParameters.single;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@function::foo::@formalParameter::x
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @36
        expression: UnqualifiedNameExpression
          name: a @37
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: int
          staticType: int
        name: SimpleIdentifier
          token: a @37
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
      annotation_1: Annotation
        atSign: @ @65
        expression: UnqualifiedNameExpression
          name: b @66
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::b
            type: int
          staticType: int
        name: SimpleIdentifier
          token: b @66
          element: <testLibrary>::@getter::b
          staticType: null
        element: <testLibrary>::@getter::b
  fragments
    #F0
      metadata
        annotation_0
    #F1
      metadata
        annotation_1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F4
        #F5 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          constantInitializer2: expression_1
            IntegerLiteral
              literal: 0 @23
              staticType: int
          inducedGetter: #F6
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
        #F6 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F5
      functions
        #F7 isOriginDeclaration isStatic foo (nameOffset:32) (firstTokenOffset:27) (offset:32)
          element: <testLibrary>::@function::foo
          nextFragment: #F8
          formalParameters
            #F0 requiredPositional isOriginDeclaration x (nameOffset:43) (firstTokenOffset:36) (offset:43)
              element: <testLibrary>::@function::foo::@formalParameter::x
              metadata
                annotation_0
              nextFragment: #F1
        #F8 isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:61) (firstTokenOffset:48) (offset:61)
          element: <testLibrary>::@function::foo
          previousFragment: #F7
          formalParameters
            #F1 requiredPositional isOriginDeclaration x (nameOffset:72) (firstTokenOffset:65) (offset:72)
              element: <testLibrary>::@function::foo::@formalParameter::x
              metadata
                annotation_1
              previousFragment: #F0
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F5
      type: int
      constantInitializer2: expression_1
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
  functions
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional x
          firstFragment: #F0
          type: int
          metadata
            annotation_0
            annotation_1
      returnType: void
''');
  }

  test_metadata_simpleFormalParameter_augmentation_topLevelFunction_inIntroductory_first() async {
    var library = await buildLibrary(r'''
const a = null;

void foo(@a int x);

augment void foo(int x) {}
''');
    // Check metadata without asking any other properties, reaching the
    // element via the augmentation, so the introductory fragment is not read.
    var foo = library.getTopLevelFunction('foo')!;
    var x = foo.fragments.last.formalParameters.single.element;
    configuration.withCombinedFragmentData(x, CombinedFragmentData.metadata);
    checkElementText(library, r'''
combinedFragmentData
  element: <testLibrary>::@function::foo::@formalParameter::x
  combined
    metadata
      annotation_0: Annotation
        atSign: @ @26
        expression: UnqualifiedNameExpression
          name: a @27
          resolution: GetterInvocationResolution
            element: <testLibrary>::@getter::a
            type: dynamic
          staticType: dynamic
        name: SimpleIdentifier
          token: a @27
          element: <testLibrary>::@getter::a
          staticType: null
        element: <testLibrary>::@getter::a
  fragments
    #F0
      metadata
        annotation_0
    #F1
library
  reference: <testLibrary>
  fragments
    #F2 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F4
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
      functions
        #F5 isOriginDeclaration isStatic foo (nameOffset:22) (firstTokenOffset:17) (offset:22)
          element: <testLibrary>::@function::foo
          nextFragment: #F6
          formalParameters
            #F0 requiredPositional isOriginDeclaration x (nameOffset:33) (firstTokenOffset:26) (offset:33)
              element: <testLibrary>::@function::foo::@formalParameter::x
              metadata
                annotation_0
              nextFragment: #F1
        #F6 isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@function::foo
          previousFragment: #F5
          formalParameters
            #F1 requiredPositional isOriginDeclaration x (nameOffset:59) (firstTokenOffset:55) (offset:59)
              element: <testLibrary>::@function::foo::@formalParameter::x
              previousFragment: #F0
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional x
          firstFragment: #F0
          type: int
          metadata
            annotation_0
      returnType: void
''');
  }

  test_metadata_simpleFormalParameter_method() async {
    var library = await buildLibrary(r'''
const a = null;

class C {
  m(@a x) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F4 requiredPositional hasImplicitType isOriginDeclaration x (nameOffset:34) (firstTokenOffset:31) (offset:34)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::x
                  metadata
                    annotation_0: Annotation
                      atSign: @ @31
                      expression: UnqualifiedNameExpression
                        name: a @32
                        resolution: GetterInvocationResolution
                          element: <testLibrary>::@getter::a
                          type: dynamic
                        staticType: dynamic
                      name: SimpleIdentifier
                        token: a @32
                        element: <testLibrary>::@getter::a
                        staticType: null
                      element: <testLibrary>::@getter::a
      topLevelVariables
        #F5 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F6
      getters
        #F6 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F5
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        hasImplicitReturnType isOriginDeclaration m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional hasImplicitType x
              firstFragment: #F4
              type: dynamic
              metadata
                annotation_0
          returnType: dynamic
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F5
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_simpleFormalParameter_unit_setter() async {
    var library = await buildLibrary(r'''
const a = null;

set foo(@a int x) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F2
        #F3 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
      setters
        #F4 hasImplicitReturnType isComplete isOriginDeclaration isStatic foo (nameOffset:21) (firstTokenOffset:17) (offset:21)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F5 requiredPositional isOriginDeclaration x (nameOffset:32) (firstTokenOffset:25) (offset:32)
              element: <testLibrary>::@setter::foo::@formalParameter::x
              metadata
                annotation_0: Annotation
                  atSign: @ @25
                  expression: UnqualifiedNameExpression
                    name: a @26
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @26
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    isOriginGetterSetter isStatic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F3
      type: int
      setter: <testLibrary>::@setter::foo
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  setters
    hasImplicitReturnType isOriginDeclaration isStatic foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional x
          firstFragment: #F5
          type: int
          metadata
            annotation_0
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_simpleFormalParameter_withDefault() async {
    var library = await buildLibrary(r'''
const a = null;
f([@a x = null]) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
      functions
        #F3 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@function::f
          formalParameters
            #F4 optionalPositional hasImplicitType isOriginDeclaration x (nameOffset:22) (firstTokenOffset:19) (offset:22)
              element: <testLibrary>::@function::f::@formalParameter::x
              metadata
                annotation_0: Annotation
                  atSign: @ @19
                  expression: UnqualifiedNameExpression
                    name: a @20
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @20
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
              constantInitializer2: expression_1
                NullLiteral
                  literal: null @26
                  staticType: Null
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    hasImplicitReturnType isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      formalParameters
        #E0 optionalPositional hasDefaultValue hasImplicitType x
          firstFragment: #F4
          type: dynamic
          metadata
            annotation_0
          constantInitializer2: expression_1
      returnType: dynamic
''');
  }

  test_metadata_superFormalParameter() async {
    var library = await buildLibrary(r'''
const a = null;

class A {
  A(int x);
}

class B extends A {
  B(@a super.x);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 29
              formalParameters
                #F3 requiredPositional isOriginDeclaration x (nameOffset:35) (firstTokenOffset:31) (offset:35)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
        #F4 hasExtendsClause class B (nameOffset:48) (firstTokenOffset:42) (offset:48)
          element: <testLibrary>::@class::B
          constructors
            #F5 isComplete isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:64) (offset:64)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 64
              formalParameters
                #F6 requiredPositional hasImplicitType isFinal isOriginDeclaration super.x (nameOffset:75) (firstTokenOffset:66) (offset:75)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::x
                  metadata
                    annotation_0: Annotation
                      atSign: @ @66
                      expression: UnqualifiedNameExpression
                        name: a @67
                        resolution: GetterInvocationResolution
                          element: <testLibrary>::@getter::a
                          type: dynamic
                        staticType: dynamic
                      name: SimpleIdentifier
                        token: a @67
                        element: <testLibrary>::@getter::a
                        staticType: null
                      element: <testLibrary>::@getter::a
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F8
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F3
              type: int
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional hasImplicitType isFinal super.x
              firstFragment: #F6
              type: int
              metadata
                annotation_0
              superConstructorParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
          superConstructor: <testLibrary>::@class::A::@constructor::new
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_topLevelVariableDeclaration() async {
    var library = await buildLibrary(r'''
const a = null;
@a
int v;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F2
        #F3 isOriginDeclaration isStatic v (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::v
          metadata
            annotation_0: Annotation
              atSign: @ @16
              expression: UnqualifiedNameExpression
                name: a @17
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: dynamic
                staticType: dynamic
              name: SimpleIdentifier
                token: a @17
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          inducedGetter: #F4
          inducedSetter: #F5
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::v
          inducingVariable: #F3
      setters
        #F5 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@setter::v
          inducingVariable: #F3
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    isOriginDeclaration isStatic v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F3
      metadata
        annotation_0
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic v
      reference: <testLibrary>::@getter::v
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    isOriginVariable isStatic v
      reference: <testLibrary>::@setter::v
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_metadata_typeParameter_ofClass() async {
    var library = await buildLibrary(r'''
const a = null;

class C<@a T> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:28) (firstTokenOffset:25) (offset:28)
              element: #E0 T
              metadata
                annotation_0: Annotation
                  atSign: @ @25
                  expression: UnqualifiedNameExpression
                    name: a @26
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @26
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F4 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F5
      getters
        #F5 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F4
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            annotation_0
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_typeParameter_ofClassTypeAlias() async {
    var library = await buildLibrary(r'''
const a = null;
class C<@a T> = D with E;

class D {}

class E {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 isMixinApplication class C (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:27) (firstTokenOffset:24) (offset:27)
              element: #E0 T
              metadata
                annotation_0: Annotation
                  atSign: @ @24
                  expression: UnqualifiedNameExpression
                    name: a @25
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @25
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
          constructors
            #F3 isOriginMixinApplication new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F4 class D (nameOffset:49) (firstTokenOffset:43) (offset:49)
          element: <testLibrary>::@class::D
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
        #F6 class E (nameOffset:61) (firstTokenOffset:55) (offset:61)
          element: <testLibrary>::@class::E
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@class::E::@constructor::new
              typeName: E
      topLevelVariables
        #F8 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F9
      getters
        #F9 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F8
  classes
    isMixinApplication isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            annotation_0
      supertype: D
      mixins
        E
      constructors
        hasEnclosingTypeParameterReference isOriginMixinApplication new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::D::@constructor::new
          superConstructor: <testLibrary>::@class::D::@constructor::new
    isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F5
    isSimplyBounded class E
      reference: <testLibrary>::@class::E
      firstFragment: #F6
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::E::@constructor::new
          firstFragment: #F7
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_typeParameter_ofFunction() async {
    var library = await buildLibrary(r'''
const a = null;
f<@a T>() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
      functions
        #F3 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@function::f
          typeParameters
            #F4 T (nameOffset:21) (firstTokenOffset:18) (offset:21)
              element: #E0 T
              metadata
                annotation_0: Annotation
                  atSign: @ @18
                  expression: UnqualifiedNameExpression
                    name: a @19
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @19
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
  functions
    hasImplicitReturnType isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
          metadata
            annotation_0
      returnType: dynamic
''');
  }

  test_metadata_typeParameter_ofTypedef() async {
    var library = await buildLibrary(r'''
const a = null;
typedef F<@a T>();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:24) (firstTokenOffset:16) (offset:24)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T (nameOffset:29) (firstTokenOffset:26) (offset:29)
              element: #E0 T
              metadata
                annotation_0: Annotation
                  atSign: @ @26
                  expression: UnqualifiedNameExpression
                    name: a @27
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@getter::a
                      type: dynamic
                    staticType: dynamic
                  name: SimpleIdentifier
                    token: a @27
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
      topLevelVariables
        #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
          inducedGetter: #F4
      getters
        #F4 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F3
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            annotation_0
      aliasedType: dynamic Function()
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F3
      type: dynamic
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_unit_topLevelVariable_first() async {
    var library = await buildLibrary(r'''
const a = 0;
@a
int x = 0;
''');
    // Check metadata without asking any other properties.
    var x = library.getTopLevelVariable('x')!;
    expect(x.metadata.annotations, hasLength(1));
    // Check details.
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          constantInitializer2: expression_0
            IntegerLiteral
              literal: 0 @10
              staticType: int
          inducedGetter: #F2
        #F3 hasInitializer isOriginDeclaration isStatic x (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::x
          metadata
            annotation_0: Annotation
              atSign: @ @13
              expression: UnqualifiedNameExpression
                name: a @14
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@getter::a
                  type: int
                staticType: int
              name: SimpleIdentifier
                token: a @14
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          inducedGetter: #F4
          inducedSetter: #F5
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F4 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::x
          inducingVariable: #F3
      setters
        #F5 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::x
          inducingVariable: #F3
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer2: expression_0
      getter: <testLibrary>::@getter::a
    hasInitializer isOriginDeclaration isStatic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F3
      metadata
        annotation_0
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_metadata_value_class_staticField() async {
    var library = await buildLibrary(r'''
class A {
  static const x = 0;
}

@A.x
class C {}
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
            #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::x
              constantInitializer2: expression_0
                IntegerLiteral
                  literal: 0 @29
                  staticType: int
              inducedGetter: #F3
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::x
              inducingVariable: #F2
        #F5 class C (nameOffset:46) (firstTokenOffset:35) (offset:46)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @35
              expression: ReceiverPropertyExtraction
                receiver: StaticQualifier
                  name: A @36
                  element: <testLibrary>::@class::A
                operator: . @37
                name: x @38
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@class::A::@getter::x
                  type: int
                staticType: int
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: A @36
                  element: <testLibrary>::@class::A
                  staticType: null
                period: . @37
                identifier: SimpleIdentifier
                  token: x @38
                  element: <testLibrary>::@class::A::@getter::x
                  staticType: null
                element: <testLibrary>::@class::A::@getter::x
                staticType: null
              element: <testLibrary>::@class::A::@getter::x
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: int
          constantInitializer2: expression_0
          getter: <testLibrary>::@class::A::@getter::x
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        isOriginVariable isStatic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::x
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
''');
  }

  test_metadata_value_enum_constant() async {
    var library = await buildLibrary(r'''
enum E { a, b, c }

@E.b
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:31) (firstTokenOffset:20) (offset:31)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @20
              expression: ReceiverPropertyExtraction
                receiver: StaticQualifier
                  name: E @21
                  element: <testLibrary>::@enum::E
                operator: . @22
                name: b @23
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@enum::E::@getter::b
                  type: E
                staticType: E
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: E @21
                  element: <testLibrary>::@enum::E
                  staticType: null
                period: . @22
                identifier: SimpleIdentifier
                  token: b @23
                  element: <testLibrary>::@enum::E::@getter::b
                  staticType: null
                element: <testLibrary>::@enum::E::@getter::b
                staticType: null
              element: <testLibrary>::@enum::E::@getter::b
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F3 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          fields
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic a (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: <testLibrary>::@enum::E::@field::a
              constantInitializer2: expression_0
                ConstructorInvocation
                  constructorReference: ConstructorReference2
                    typeReference: ConstructorTypeReference
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              constantInitializer: expression_1
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
              inducedGetter: #F5
            #F6 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic b (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@enum::E::@field::b
              constantInitializer2: expression_2
                ConstructorInvocation
                  constructorReference: ConstructorReference2
                    typeReference: ConstructorTypeReference
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              constantInitializer: expression_3
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
              inducedGetter: #F7
            #F8 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic c (nameOffset:15) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@enum::E::@field::c
              constantInitializer2: expression_4
                ConstructorInvocation
                  constructorReference: ConstructorReference2
                    typeReference: ConstructorTypeReference
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
              constantInitializer: expression_5
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
              inducedGetter: #F9
            #F10 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              constantInitializer2: expression_6
                ListLiteral
                  leftBracket: [ @0
                  elements2
                    UnqualifiedNameExpression
                      name: a @-1
                      resolution: GetterInvocationResolution
                        element: <testLibrary>::@enum::E::@getter::a
                        type: E
                      staticType: E
                    UnqualifiedNameExpression
                      name: b @-1
                      resolution: GetterInvocationResolution
                        element: <testLibrary>::@enum::E::@getter::b
                        type: E
                      staticType: E
                    UnqualifiedNameExpression
                      name: c @-1
                      resolution: GetterInvocationResolution
                        element: <testLibrary>::@enum::E::@getter::c
                        type: E
                      staticType: E
                  elements(v1)
                    SimpleIdentifier
                      token: a @-1
                      element: <testLibrary>::@enum::E::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      element: <testLibrary>::@enum::E::@getter::b
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      element: <testLibrary>::@enum::E::@getter::c
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F11
          constructors
            #F12 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::E::@getter::a
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@enum::E::@getter::b
              inducingVariable: #F6
            #F9 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@enum::E::@getter::c
              inducingVariable: #F8
            #F11 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F10
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F3
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F4
          type: E
          constantInitializer2: expression_0
          constantInitializer: expression_1
          getter: <testLibrary>::@enum::E::@getter::a
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F6
          type: E
          constantInitializer2: expression_2
          constantInitializer: expression_3
          getter: <testLibrary>::@enum::E::@getter::b
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer c
          reference: <testLibrary>::@enum::E::@field::c
          firstFragment: #F8
          type: E
          constantInitializer2: expression_4
          constantInitializer: expression_5
          getter: <testLibrary>::@enum::E::@getter::c
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F10
          type: List<E>
          constantInitializer2: expression_6
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F12
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        isOriginVariable isStatic b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        isOriginVariable isStatic c
          reference: <testLibrary>::@enum::E::@getter::c
          firstFragment: #F9
          returnType: E
          variable: <testLibrary>::@enum::E::@field::c
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F11
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_metadata_value_extension_staticField() async {
    var library = await buildLibrary(r'''
extension E on int {
  static const x = 0;
}

@E.x
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:57) (firstTokenOffset:46) (offset:57)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @46
              expression: ReceiverPropertyExtraction
                receiver: StaticQualifier
                  name: E @47
                  element: <testLibrary>::@extension::E
                operator: . @48
                name: x @49
                resolution: GetterInvocationResolution
                  element: <testLibrary>::@extension::E::@getter::x
                  type: int
                staticType: int
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: E @47
                  element: <testLibrary>::@extension::E
                  staticType: null
                period: . @48
                identifier: SimpleIdentifier
                  token: x @49
                  element: <testLibrary>::@extension::E::@getter::x
                  staticType: null
                element: <testLibrary>::@extension::E::@getter::x
                staticType: null
              element: <testLibrary>::@extension::E::@getter::x
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      extensions
        #F3 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          fields
            #F4 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic x (nameOffset:36) (firstTokenOffset:36) (offset:36)
              element: <testLibrary>::@extension::E::@field::x
              constantInitializer2: expression_0
                IntegerLiteral
                  literal: 0 @40
                  staticType: int
              inducedGetter: #F5
          getters
            #F5 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@extension::E::@getter::x
              inducingVariable: #F4
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F3
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer x
          reference: <testLibrary>::@extension::E::@field::x
          firstFragment: #F4
          type: int
          constantInitializer2: expression_0
          getter: <testLibrary>::@extension::E::@getter::x
      getters
        isOriginVariable isStatic x
          reference: <testLibrary>::@extension::E::@getter::x
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extension::E::@field::x
''');
  }

  test_metadata_value_extension_staticField_unnamed() async {
    var library = await buildLibrary(r'''
extension on Object {
  @foo
  static const foo = 0;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension <null-name> (nameOffset:<null>) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@extension::#0
          fields
            #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:44) (firstTokenOffset:44) (offset:44)
              element: <testLibrary>::@extension::#0::@field::foo
              metadata
                annotation_0: Annotation
                  atSign: @ @24
                  expression: UnqualifiedNameExpression
                    name: foo @25
                    resolution: GetterInvocationResolution
                      element: <testLibrary>::@extension::#0::@getter::foo
                      type: int
                    staticType: int
                  name: SimpleIdentifier
                    token: foo @25
                    element: <testLibrary>::@extension::#0::@getter::foo
                    staticType: null
                  element: <testLibrary>::@extension::#0::@getter::foo
              constantInitializer2: expression_0
                IntegerLiteral
                  literal: 0 @50
                  staticType: int
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extension::#0::@getter::foo
              inducingVariable: #F2
  extensions
    extension <null-name>
      reference: <testLibrary>::@extension::#0
      firstFragment: #F1
      extendedType: Object
      onDeclaration: dart:core::@class::Object
      fields
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
          reference: <testLibrary>::@extension::#0::@field::foo
          firstFragment: #F2
          metadata
            annotation_0
          type: int
          constantInitializer2: expression_0
          getter: <testLibrary>::@extension::#0::@getter::foo
      getters
        isOriginVariable isStatic foo
          reference: <testLibrary>::@extension::#0::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extension::#0::@field::foo
''');
  }

  test_metadata_value_prefix_extension_staticField() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  static const x = 0;
}
''');
    var library = await buildLibrary(r'''
import 'foo.dart' as foo;

@foo.E.x
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix::foo
          fragments: @21
      classes
        #F1 class C (nameOffset:42) (firstTokenOffset:27) (offset:42)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @27
              expression: ReceiverPropertyExtraction
                receiver: StaticQualifier
                  importPrefix: ImportPrefixReference
                    name: foo @28
                    period: . @31
                    element: <testLibraryFragment>::@prefix::foo
                  name: E @32
                  element: package:test/foo.dart::@extension::E
                operator: . @33
                name: x @34
                resolution: GetterInvocationResolution
                  element: package:test/foo.dart::@extension::E::@getter::x
                  type: int
                staticType: int
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @28
                  element: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @31
                identifier: SimpleIdentifier
                  token: E @32
                  element: package:test/foo.dart::@extension::E
                  staticType: null
                element: package:test/foo.dart::@extension::E
                staticType: null
              period: . @33
              constructorName: SimpleIdentifier
                token: x @34
                element: package:test/foo.dart::@extension::E::@getter::x
                staticType: null
              element: package:test/foo.dart::@extension::E::@getter::x
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_instanceCreation_argument_super() async {
    var library = await buildLibrary(r'''
class A {
  const A(_);
}

@A(super)
class C {}
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
                #F3 requiredPositional hasImplicitType isOriginDeclaration _ (nameOffset:20) (firstTokenOffset:20) (offset:20)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
        #F4 class C (nameOffset:43) (firstTokenOffset:27) (offset:43)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @27
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @28
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @29
                  arguments2
                    InvalidSuperExpression
                      superReference: SuperReference
                        superKeyword: super @30
                      staticType: InvalidType
                  arguments(v1)
                    SuperExpression
                      superKeyword: super @30
                      staticType: InvalidType
                  rightParenthesis: ) @35
                staticType: A
              name: SimpleIdentifier
                token: A @28
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @29
                arguments
                  SuperExpression
                    superKeyword: super @30
                    staticType: InvalidType
                rightParenthesis: ) @35
              element: <testLibrary>::@class::A::@constructor::new
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional hasImplicitType _
              firstFragment: #F3
              type: dynamic
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_unresolved_annotation_instanceCreation_argument_this() async {
    var library = await buildLibrary(r'''
class A {
  const A(_);
}

@A(this)
class C {}
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
                #F3 requiredPositional hasImplicitType isOriginDeclaration _ (nameOffset:20) (firstTokenOffset:20) (offset:20)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
        #F4 class C (nameOffset:42) (firstTokenOffset:27) (offset:42)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @27
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: A @28
                    element: <testLibrary>::@class::A
                    type: A
                  element: <testLibrary>::@class::A::@constructor::new
                argumentList: ArgumentList
                  leftParenthesis: ( @29
                  arguments2
                    ThisExpression
                      thisKeyword: this @30
                      staticType: InvalidType
                  rightParenthesis: ) @34
                staticType: A
              name: SimpleIdentifier
                token: A @28
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @29
                arguments
                  ThisExpression
                    thisKeyword: this @30
                    staticType: InvalidType
                rightParenthesis: ) @34
              element: <testLibrary>::@class::A::@constructor::new
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional hasImplicitType _
              firstFragment: #F3
              type: dynamic
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
''');
  }

  test_unresolved_annotation_namedConstructorCall_noClass() async {
    var library = await buildLibrary(r'''
@foo.bar()
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:17) (firstTokenOffset:0) (offset:17)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @0
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    importPrefix: ImportPrefixReference
                      name: foo @1
                      period: . @4
                      element: <null>
                    name: bar @5
                    element: <null>
                    type: InvalidType
                  element: <null>
                argumentList: ArgumentList
                  leftParenthesis: ( @8
                  rightParenthesis: ) @9
                staticType: InvalidType
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @1
                  element: <null>
                  staticType: null
                period: . @4
                identifier: SimpleIdentifier
                  token: bar @5
                  element: <null>
                  staticType: null
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @8
                rightParenthesis: ) @9
              element: <null>
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_namedConstructorCall_noConstructor() async {
    var library = await buildLibrary(r'''
@String.foo()
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:20) (firstTokenOffset:0) (offset:20)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @0
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: String @1
                    element: dart:core::@class::String
                    type: String
                  selector: ConstructorSelector
                    period: . @7
                    name2: foo @8
                  element: <null>
                argumentList: ArgumentList
                  leftParenthesis: ( @11
                  rightParenthesis: ) @12
                staticType: String
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: String @1
                  element: dart:core::@class::String
                  staticType: null
                period: . @7
                identifier: SimpleIdentifier
                  token: foo @8
                  element: <null>
                  staticType: null
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @11
                rightParenthesis: ) @12
              element: <null>
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_prefixedIdentifier_badPrefix() async {
    var library = await buildLibrary(r'''
@foo.bar
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @0
              expression: ReceiverPropertyExtraction
                receiver: UnqualifiedNameExpression
                  name: foo @1
                  resolution: InvalidNamedReadResolution
                    recoveryElement: <null>
                  staticType: InvalidType
                operator: . @4
                name: bar @5
                resolution: InvalidNamedReadResolution
                  recoveryElement: <null>
                staticType: InvalidType
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @1
                  element: <null>
                  staticType: null
                period: . @4
                identifier: SimpleIdentifier
                  token: bar @5
                  element: <null>
                  staticType: null
                element: <null>
                staticType: null
              element: <null>
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_prefixedIdentifier_noDeclaration() async {
    var library = await buildLibrary(r'''
import "dart:async" as foo;

@foo.bar
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as foo (nameOffset:23) (firstTokenOffset:<null>) (offset:23)
      prefixes
        <testLibraryFragment>::@prefix::foo
          fragments: @23
      classes
        #F1 class C (nameOffset:44) (firstTokenOffset:29) (offset:44)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @29
              expression: ImportPrefixedNameExpression
                importPrefix: ImportPrefixReference
                  name: foo @30
                  period: . @33
                  element: <testLibraryFragment>::@prefix::foo
                name: bar @34
                resolution: InvalidNamedReadResolution
                  recoveryElement: <null>
                staticType: InvalidType
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @30
                  element: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: bar @34
                  element: <null>
                  staticType: null
                element: <null>
                staticType: null
              element: <null>
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix() async {
    var library = await buildLibrary(r'''
@foo.bar.baz()
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:21) (firstTokenOffset:0) (offset:21)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @0
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    importPrefix: ImportPrefixReference
                      name: foo @1
                      period: . @4
                      element: <null>
                    name: bar @5
                    element: <null>
                    type: InvalidType
                  selector: ConstructorSelector
                    period: . @8
                    name2: baz @9
                  element: <null>
                argumentList: ArgumentList
                  leftParenthesis: ( @12
                  rightParenthesis: ) @13
                staticType: InvalidType
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @1
                  element: <null>
                  staticType: null
                period: . @4
                identifier: SimpleIdentifier
                  token: bar @5
                  element: <null>
                  staticType: null
                element: <null>
                staticType: null
              period: . @8
              constructorName: SimpleIdentifier
                token: baz @9
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @12
                rightParenthesis: ) @13
              element: <null>
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_noClass() async {
    var library = await buildLibrary(r'''
import "dart:async" as foo;

@foo.bar.baz()
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as foo (nameOffset:23) (firstTokenOffset:<null>) (offset:23)
      prefixes
        <testLibraryFragment>::@prefix::foo
          fragments: @23
      classes
        #F1 class C (nameOffset:50) (firstTokenOffset:29) (offset:50)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @29
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    importPrefix: ImportPrefixReference
                      name: foo @30
                      period: . @33
                      element: <testLibraryFragment>::@prefix::foo
                    name: bar @34
                    element: <null>
                    type: InvalidType
                  selector: ConstructorSelector
                    period: . @37
                    name2: baz @38
                  element: <null>
                argumentList: ArgumentList
                  leftParenthesis: ( @41
                  rightParenthesis: ) @42
                staticType: InvalidType
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @30
                  element: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: bar @34
                  element: <null>
                  staticType: null
                element: <null>
                staticType: null
              period: . @37
              constructorName: SimpleIdentifier
                token: baz @38
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @41
                rightParenthesis: ) @42
              element: <null>
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_noConstructor() async {
    var library = await buildLibrary(r'''
import "dart:async" as foo;

@foo.Future.bar()
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as foo (nameOffset:23) (firstTokenOffset:<null>) (offset:23)
      prefixes
        <testLibraryFragment>::@prefix::foo
          fragments: @23
      classes
        #F1 class C (nameOffset:53) (firstTokenOffset:29) (offset:53)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @29
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    importPrefix: ImportPrefixReference
                      name: foo @30
                      period: . @33
                      element: <testLibraryFragment>::@prefix::foo
                    name: Future @34
                    element: dart:async::@class::Future
                    type: Future<dynamic>
                  selector: ConstructorSelector
                    period: . @40
                    name2: bar @41
                  element: <null>
                argumentList: ArgumentList
                  leftParenthesis: ( @44
                  rightParenthesis: ) @45
                staticType: Future<dynamic>
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @30
                  element: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: Future @34
                  element: dart:async::@class::Future
                  staticType: null
                element: dart:async::@class::Future
                staticType: null
              period: . @40
              constructorName: SimpleIdentifier
                token: bar @41
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @44
                rightParenthesis: ) @45
              element: <null>
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix() async {
    var library = await buildLibrary(r'''
@foo.bar()
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:17) (firstTokenOffset:0) (offset:17)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @0
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    importPrefix: ImportPrefixReference
                      name: foo @1
                      period: . @4
                      element: <null>
                    name: bar @5
                    element: <null>
                    type: InvalidType
                  element: <null>
                argumentList: ArgumentList
                  leftParenthesis: ( @8
                  rightParenthesis: ) @9
                staticType: InvalidType
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @1
                  element: <null>
                  staticType: null
                period: . @4
                identifier: SimpleIdentifier
                  token: bar @5
                  element: <null>
                  staticType: null
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @8
                rightParenthesis: ) @9
              element: <null>
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_prefixedUnnamedConstructorCall_noClass() async {
    var library = await buildLibrary(r'''
import "dart:async" as foo;

@foo.bar()
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as foo (nameOffset:23) (firstTokenOffset:<null>) (offset:23)
      prefixes
        <testLibraryFragment>::@prefix::foo
          fragments: @23
      classes
        #F1 class C (nameOffset:46) (firstTokenOffset:29) (offset:46)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @29
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    importPrefix: ImportPrefixReference
                      name: foo @30
                      period: . @33
                      element: <testLibraryFragment>::@prefix::foo
                    name: bar @34
                    element: <null>
                    type: InvalidType
                  element: <null>
                argumentList: ArgumentList
                  leftParenthesis: ( @37
                  rightParenthesis: ) @38
                staticType: InvalidType
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: foo @30
                  element: <testLibraryFragment>::@prefix::foo
                  staticType: null
                period: . @33
                identifier: SimpleIdentifier
                  token: bar @34
                  element: <null>
                  staticType: null
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @37
                rightParenthesis: ) @38
              element: <null>
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_simpleIdentifier() async {
    var library = await buildLibrary(r'''
@foo
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:11) (firstTokenOffset:0) (offset:11)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @0
              expression: UnqualifiedNameExpression
                name: foo @1
                resolution: InvalidNamedReadResolution
                  recoveryElement: <null>
                staticType: InvalidType
              name: SimpleIdentifier
                token: foo @1
                element: <null>
                staticType: null
              element: <null>
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_simpleIdentifier_multiplyDefined() async {
    if (!keepLinkingLibraries) return;

    newFile('$testPackageLibPath/a.dart', r'''
const v = 0;
''');
    newFile('$testPackageLibPath/b.dart', r'''
const v = 0;
''');
    var library = await buildLibrary(r'''
import 'a.dart';
import 'b.dart';

@v
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
        package:test/b.dart
      classes
        #F1 class C (nameOffset:44) (firstTokenOffset:35) (offset:44)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @35
              expression: UnqualifiedNameExpression
                name: v @36
                resolution: InvalidNamedReadResolution
                  recoveryElement: multiplyDefinedElement
                    package:test/a.dart::@getter::v
                    package:test/b.dart::@getter::v
                staticType: InvalidType
              name: SimpleIdentifier
                token: v @36
                element: multiplyDefinedElement
                  package:test/a.dart::@getter::v
                  package:test/b.dart::@getter::v
                staticType: null
              element: multiplyDefinedElement
                package:test/a.dart::@getter::v
                package:test/b.dart::@getter::v
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }

  test_unresolved_annotation_unnamedConstructorCall_noClass() async {
    var library = await buildLibrary(r'''
@foo()
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:13) (firstTokenOffset:0) (offset:13)
          element: <testLibrary>::@class::C
          metadata
            annotation_0: Annotation
              atSign: @ @0
              expression: ConstructorInvocation
                constructorReference: ConstructorReference2
                  typeReference: ConstructorTypeReference
                    name: foo @1
                    element: <null>
                    type: InvalidType
                  element: <null>
                argumentList: ArgumentList
                  leftParenthesis: ( @4
                  rightParenthesis: ) @5
                staticType: InvalidType
              name: SimpleIdentifier
                token: foo @1
                element: <null>
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @4
                rightParenthesis: ) @5
              element: <null>
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      metadata
        annotation_0
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
''');
  }
}

@reflectiveTest
class MetadataElementTest_fromBytes extends MetadataElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MetadataElementTest_keepLinking extends MetadataElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
