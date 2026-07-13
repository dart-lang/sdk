// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeElementTest_keepLinking);
    defineReflectiveTests(ExtensionTypeElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class ExtensionTypeElementTest extends ElementsBaseTest {
  test_constructor_primary_body_constantInitializers_assertInitializer() async {
    var library = await buildLibrary(r'''
extension type const E(int it) {
  this : assert(it > 0);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:21) (firstTokenOffset:0) (offset:21)
          element: <testLibrary>::@extensionType::E
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@extensionType::E::@constructor::new
              typeName: E
              typeNameOffset: 21
              thisKeywordOffset: 35
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
      constructors
        isConst isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::E::@field::it
          constantInitializers
            AssertInitializer
              assertKeyword: assert @42
              leftParenthesis: ( @48
              condition: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: it @49
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
                  staticType: int
                operator: > @52
                rightOperand: IntegerLiteral
                  literal: 0 @54
                  staticType: int
                element: dart:core::@class::num::@method::>
                staticInvokeType: bool Function(num)
                staticType: bool
              rightParenthesis: ) @55
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
''');
  }

  test_constructor_primary_body_duplicate() async {
    var library = await buildLibrary(r'''
extension type const E(int it) {
  @Deprecated('0')
  this : assert(it >= 0);
  @Deprecated('1')
  this : assert(it >= 1);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:21) (firstTokenOffset:0) (offset:21)
          element: <testLibrary>::@extensionType::E
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@extensionType::E::@constructor::new
              metadata
                Annotation
                  atSign: @ @35
                  name: SimpleIdentifier
                    token: Deprecated @36
                    element: dart:core::@class::Deprecated
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @46
                    arguments
                      SimpleStringLiteral
                        literal: '0' @47
                    rightParenthesis: ) @50
                  element: dart:core::@class::Deprecated::@constructor::new
              typeName: E
              typeNameOffset: 21
              thisKeywordOffset: 54
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
      constructors
        isConst isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F4
          metadata
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: Deprecated @36
                element: dart:core::@class::Deprecated
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @46
                arguments
                  SimpleStringLiteral
                    literal: '0' @47
                rightParenthesis: ) @50
              element: dart:core::@class::Deprecated::@constructor::new
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::E::@field::it
          constantInitializers
            AssertInitializer
              assertKeyword: assert @61
              leftParenthesis: ( @67
              condition: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: it @68
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
                  staticType: int
                operator: >= @71
                rightOperand: IntegerLiteral
                  literal: 0 @74
                  staticType: int
                element: dart:core::@class::num::@method::>=
                staticInvokeType: bool Function(num)
                staticType: bool
              rightParenthesis: ) @75
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
''');
  }

  test_constructor_primary_body_metadata() async {
    var library = await buildLibrary(r'''
extension type E(int it) {
  @deprecated
  this;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::E
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::E::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::E::@constructor::new
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: deprecated @30
                    element: dart:core::@getter::deprecated
                    staticType: null
                  element: dart:core::@getter::deprecated
              typeName: E
              typeNameOffset: 15
              thisKeywordOffset: 43
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::E::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F4
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: deprecated @30
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::E::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
''');
  }

  test_constructor_primary_body_named() async {
    var library = await buildLibrary(r'''
extension type const E.named(int it) {
  this : assert(it > 0);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:21) (firstTokenOffset:0) (offset:21)
          element: <testLibrary>::@extensionType::E
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isConst isOriginDeclaration isPrimary named (nameOffset:23) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@extensionType::E::@constructor::named
              typeName: E
              typeNameOffset: 21
              periodOffset: 22
              thisKeywordOffset: 41
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:33) (firstTokenOffset:29) (offset:33)
                  element: <testLibrary>::@extensionType::E::@constructor::named::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::named
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::named::@formalParameter::it
      constructors
        isConst isExtensionTypeMember isOriginDeclaration isPrimary named
          reference: <testLibrary>::@extensionType::E::@constructor::named
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::E::@field::it
          constantInitializers
            AssertInitializer
              assertKeyword: assert @48
              leftParenthesis: ( @54
              condition: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: it @55
                  element: <testLibrary>::@extensionType::E::@constructor::named::@formalParameter::it
                  staticType: int
                operator: > @58
                rightOperand: IntegerLiteral
                  literal: 0 @60
                  staticType: int
                element: dart:core::@class::num::@method::>
                staticInvokeType: bool Function(num)
                staticType: bool
              rightParenthesis: ) @61
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
''');
  }

  test_constructor_primary_body_primaryInitializerScope() async {
    var library = await buildLibrary(r'''
extension type const E(int it) {
  this : assert(it > 0);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:21) (firstTokenOffset:0) (offset:21)
          element: <testLibrary>::@extensionType::E
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@extensionType::E::@constructor::new
              typeName: E
              typeNameOffset: 21
              thisKeywordOffset: 35
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
      constructors
        isConst isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::E::@field::it
          constantInitializers
            AssertInitializer
              assertKeyword: assert @42
              leftParenthesis: ( @48
              condition: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: it @49
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
                  staticType: int
                operator: > @52
                rightOperand: IntegerLiteral
                  literal: 0 @54
                  staticType: int
                element: dart:core::@class::num::@method::>
                staticInvokeType: bool Function(num)
                staticType: bool
              rightParenthesis: ) @55
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
''');
  }

  test_constructor_primary_const() async {
    var library = await buildLibrary(r'''
extension type const A(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:21) (firstTokenOffset:0) (offset:21)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 21
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isConst isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_field_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A({this.it = 0}) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalNamed hasImplicitType isFinal isOriginDeclaration this.it (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @28
                      staticType: int
          getters
            #F3 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed hasDefaultValue hasImplicitType isFinal this.it
              firstFragment: #F5
              type: dynamic
              constantInitializer
                fragment: #F5
                expression: expression_0
              field: <null>
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::#0
''');
  }

  test_constructor_primary_formalParameter_field_requiredPositional() async {
    var library = await buildLibrary(r'''
extension type A(this.it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 10
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional hasImplicitType isFinal isOriginDeclaration this.it (nameOffset:22) (firstTokenOffset:17) (offset:22)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isFinal this.it
              firstFragment: #F5
              type: dynamic
              field: <null>
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::#0
''');
  }

  test_constructor_primary_formalParameter_field_requiredPositional_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(this.it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 10
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional hasImplicitType isFinal isOriginDeclaration this.it (nameOffset:38) (firstTokenOffset:33) (offset:38)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isFinal this.it
              firstFragment: #F5
              type: dynamic
              field: <null>
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::#0
''');
  }

  test_constructor_primary_formalParameter_regular_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A({int? it}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 12
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalNamed isDeclaring isFinal isOriginDeclaration this.it (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed isDeclaring isFinal this.it
              firstFragment: #F5
              type: int?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_optionalNamed_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A({int? it}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 12
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 optionalNamed isDeclaring isFinal isOriginDeclaration this.it (nameOffset:39) (firstTokenOffset:34) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed isDeclaring isFinal this.it
              firstFragment: #F5
              type: int?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_optionalNamed_private() async {
    var library = await buildLibrary(r'''
extension type A({int? _it}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter isPromotable _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::_it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalNamed isDeclaring isFinal isOriginDeclaration this.it (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::_it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::_it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter isPromotable _it
          reference: <testLibrary>::@extensionType::A::@field::_it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::_it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed isDeclaring isFinal this.it
              firstFragment: #F5
              type: int?
              privateName: _it
              field: <testLibrary>::@extensionType::A::@field::_it
      getters
        isExtensionTypeMember isOriginVariable _it
          reference: <testLibrary>::@extensionType::A::@getter::_it
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::_it
''');
  }

  test_constructor_primary_formalParameter_regular_optionalNamed_type_fromDefaultValue() async {
    var library = await buildLibrary(r'''
extension type A({it = 0}) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalNamed hasImplicitType isDeclaring isFinal isOriginDeclaration this.it (nameOffset:18) (firstTokenOffset:18) (offset:18)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @23
                      staticType: int
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        hasImplicitType isFinal isOriginDeclaringFormalParameter isTypeInferredFromInitializer it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed hasDefaultValue hasImplicitType isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              constantInitializer
                fragment: #F5
                expression: expression_0
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_optionalNamed_withDefault() async {
    var library = await buildLibrary(r'''
extension type A({int a = 0}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 14
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalNamed isDeclaring isFinal isOriginDeclaration this.a (nameOffset:22) (firstTokenOffset:18) (offset:22)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @26
                      staticType: int
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed hasDefaultValue isDeclaring isFinal this.a
              firstFragment: #F5
              type: int
              constantInitializer
                fragment: #F5
                expression: expression_0
              field: <testLibrary>::@extensionType::A::@field::a
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameter_regular_optionalPositional() async {
    var library = await buildLibrary(r'''
extension type A([int? it]) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 12
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_optionalPositional_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A([int? it]) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 12
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 optionalPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:39) (firstTokenOffset:34) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_optionalPositional_type_fromDefaultValue() async {
    var library = await buildLibrary(r'''
extension type A([it = 0]) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalPositional hasImplicitType isDeclaring isFinal isOriginDeclaration this.it (nameOffset:18) (firstTokenOffset:18) (offset:18)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @23
                      staticType: int
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        hasImplicitType isFinal isOriginDeclaringFormalParameter isTypeInferredFromInitializer it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalPositional hasDefaultValue hasImplicitType isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              constantInitializer
                fragment: #F5
                expression: expression_0
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_optionalPositional_type_fromDefaultValue_chain() async {
    var library = await buildLibrary(r'''
extension type A([it = 0]) {}

extension type B(A it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalPositional hasImplicitType isDeclaring isFinal isOriginDeclaration this.it (nameOffset:18) (firstTokenOffset:18) (offset:18)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @23
                      staticType: int
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
        #F6 extension type B (nameOffset:46) (firstTokenOffset:31) (offset:46)
          element: <testLibrary>::@extensionType::B
          fields
            #F7 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@extensionType::B::@field::it
              inducedGetter: #F8
          constructors
            #F9 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:46) (offset:46)
              element: <testLibrary>::@extensionType::B::@constructor::new
              typeName: B
              typeNameOffset: 46
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:50) (firstTokenOffset:48) (offset:50)
                  element: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
          getters
            #F8 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@extensionType::B::@getter::it
              inducingVariable: #F7
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        hasImplicitType isFinal isOriginDeclaringFormalParameter isTypeInferredFromInitializer it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalPositional hasDefaultValue hasImplicitType isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              constantInitializer
                fragment: #F5
                expression: expression_0
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F6
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F7
          type: A
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::B::@constructor::new
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F10
              type: A
              field: <testLibrary>::@extensionType::B::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_optionalPositional_withDefault() async {
    var library = await buildLibrary(r'''
extension type A([int a = 0]) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 14
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalPositional isDeclaring isFinal isOriginDeclaration this.a (nameOffset:22) (firstTokenOffset:18) (offset:22)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @26
                      staticType: int
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalPositional hasDefaultValue isDeclaring isFinal this.a
              firstFragment: #F5
              type: int
              constantInitializer
                fragment: #F5
                expression: expression_0
              field: <testLibrary>::@extensionType::A::@field::a
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameter_regular_requiredNamed() async {
    var library = await buildLibrary(r'''
extension type A({required int it}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 20
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredNamed isDeclaring isFinal isOriginDeclaration this.it (nameOffset:31) (firstTokenOffset:18) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredNamed isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredNamed_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A({required int it}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 20
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredNamed isDeclaring isFinal isOriginDeclaration this.it (nameOffset:47) (firstTokenOffset:34) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredNamed isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredNamed_private() async {
    var library = await buildLibrary(r'''
extension type A({required int _it}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter isPromotable _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::_it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredNamed isDeclaring isFinal isOriginDeclaration this.it (nameOffset:31) (firstTokenOffset:18) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::_it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::_it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter isPromotable _it
          reference: <testLibrary>::@extensionType::A::@field::_it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::_it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredNamed isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              privateName: _it
              field: <testLibrary>::@extensionType::A::@field::_it
      getters
        isExtensionTypeMember isOriginVariable _it
          reference: <testLibrary>::@extensionType::A::@getter::_it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::_it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 9
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_documented() async {
    var library = await buildLibrary(r'''
extension type A(
  /// first
  /// second
  int it
) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:49) (firstTokenOffset:20) (offset:49)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  documentationComment: /// first\n/// second
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          documentationComment: /// first\n/// second
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              documentationComment: /// first\n/// second
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_final_hasType() async {
    var library = await buildLibrary(r'''
extension type A(final int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 15
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:27) (firstTokenOffset:17) (offset:27)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_final_hasType_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(final int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 15
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:43) (firstTokenOffset:33) (offset:43)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_final_implicitType() async {
    var library = await buildLibrary(r'''
extension type A(final it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 11
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional hasImplicitType isDeclaring isFinal isOriginDeclaration this.it (nameOffset:23) (firstTokenOffset:17) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        hasImplicitType isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isDeclaring isFinal this.it
              firstFragment: #F5
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_final_implicitType_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(final it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 11
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional hasImplicitType isDeclaring isFinal isOriginDeclaration this.it (nameOffset:39) (firstTokenOffset:33) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        hasImplicitType isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isDeclaring isFinal this.it
              firstFragment: #F5
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_functionTypedSuffix() async {
    var library = await buildLibrary(r'''
extension type A(int it()) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 11
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int Function()
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int Function()
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int Function()
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int Function()
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_functionTypedSuffix_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int it()) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 11
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int Function()
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int Function()
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int Function()
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int Function()
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_implicitType() async {
    var library = await buildLibrary(r'''
extension type A(it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 5
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional hasImplicitType isDeclaring isFinal isOriginDeclaration this.it (nameOffset:17) (firstTokenOffset:17) (offset:17)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        hasImplicitType isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isDeclaring isFinal this.it
              firstFragment: #F5
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_implicitType_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 5
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional hasImplicitType isDeclaring isFinal isOriginDeclaration this.it (nameOffset:33) (firstTokenOffset:33) (offset:33)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        hasImplicitType isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isDeclaring isFinal this.it
              firstFragment: #F5
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_implicitType_withMetadata() async {
    var library = await buildLibrary(r'''
extension type A(@deprecated it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 17
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional hasImplicitType isDeclaring isFinal isOriginDeclaration this.it (nameOffset:29) (firstTokenOffset:17) (offset:29)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  metadata
                    Annotation
                      atSign: @ @17
                      name: SimpleIdentifier
                        token: deprecated @18
                        element: dart:core::@getter::deprecated
                        staticType: null
                      element: dart:core::@getter::deprecated
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        hasImplicitType isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @17
              name: SimpleIdentifier
                token: deprecated @18
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isDeclaring isFinal this.it
              firstFragment: #F5
              type: Object?
              metadata
                Annotation
                  atSign: @ @17
                  name: SimpleIdentifier
                    token: deprecated @18
                    element: dart:core::@getter::deprecated
                    staticType: null
                  element: dart:core::@getter::deprecated
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_implicitType_withMetadata_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(@deprecated it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 17
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional hasImplicitType isDeclaring isFinal isOriginDeclaration this.it (nameOffset:45) (firstTokenOffset:33) (offset:45)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  metadata
                    Annotation
                      atSign: @ @33
                      name: SimpleIdentifier
                        token: deprecated @34
                        element: dart:core::@getter::deprecated
                        staticType: null
                      element: dart:core::@getter::deprecated
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        hasImplicitType isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @33
              name: SimpleIdentifier
                token: deprecated @34
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isDeclaring isFinal this.it
              firstFragment: #F5
              type: Object?
              metadata
                Annotation
                  atSign: @ @33
                  name: SimpleIdentifier
                    token: deprecated @34
                    element: dart:core::@getter::deprecated
                    staticType: null
                  element: dart:core::@getter::deprecated
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_invalidKeyword_const() async {
    var library = await buildLibrary(r'''
extension type A(const int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 15
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:27) (firstTokenOffset:17) (offset:27)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_invalidKeyword_const_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(const int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 15
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:43) (firstTokenOffset:33) (offset:43)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_invalidKeyword_covariant() async {
    var library = await buildLibrary(r'''
extension type A(covariant int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isExplicitlyCovariant isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 19
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:31) (firstTokenOffset:17) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isCovariant isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_invalidKeyword_covariant_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(covariant int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isExplicitlyCovariant isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 19
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:47) (firstTokenOffset:33) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isCovariant isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_invalidKeyword_required() async {
    var library = await buildLibrary(r'''
extension type A(required int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 18
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:30) (firstTokenOffset:17) (offset:30)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_invalidKeyword_static() async {
    var library = await buildLibrary(r'''
extension type A(static int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 16
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:28) (firstTokenOffset:24) (offset:28)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 9
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_metadata() async {
    var library = await buildLibrary(r'''
extension type A(@deprecated int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 21
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:33) (firstTokenOffset:17) (offset:33)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  metadata
                    Annotation
                      atSign: @ @17
                      name: SimpleIdentifier
                        token: deprecated @18
                        element: dart:core::@getter::deprecated
                        staticType: null
                      element: dart:core::@getter::deprecated
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @17
              name: SimpleIdentifier
                token: deprecated @18
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              metadata
                Annotation
                  atSign: @ @17
                  name: SimpleIdentifier
                    token: deprecated @18
                    element: dart:core::@getter::deprecated
                    staticType: null
                  element: dart:core::@getter::deprecated
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_name_sameAsExtensionType() async {
    var library = await buildLibrary(r'''
extension type A(int A) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::A
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 8
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.A (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::A
          getters
            #F3 isComplete isOriginVariable A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::A
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::A
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter A
          reference: <testLibrary>::@extensionType::A::@field::A
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::A
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::A
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.A
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::A
      getters
        isExtensionTypeMember isOriginVariable A
          reference: <testLibrary>::@extensionType::A::@getter::A
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::A
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_name_sameAsExtensionType_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int A) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::A
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 8
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.A (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::A
          getters
            #F3 isComplete isOriginVariable A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::A
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::A
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter A
          reference: <testLibrary>::@extensionType::A::@field::A
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::A
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::A
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.A
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::A
      getters
        isExtensionTypeMember isOriginVariable A
          reference: <testLibrary>::@extensionType::A::@getter::A
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::A
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_var() async {
    var library = await buildLibrary(r'''
extension type A(var it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 9
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional hasImplicitType isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        hasImplicitType isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isDeclaring isFinal this.it
              firstFragment: #F5
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_var_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(var it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 9
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional hasImplicitType isDeclaring isFinal isOriginDeclaration this.it (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        hasImplicitType isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isDeclaring isFinal this.it
              firstFragment: #F5
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameter_super_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A({super.it = 0}) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalNamed hasImplicitType isFinal isOriginDeclaration super.it (nameOffset:24) (firstTokenOffset:18) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @29
                      staticType: int
          getters
            #F3 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed hasDefaultValue hasImplicitType isFinal super.it
              firstFragment: #F5
              type: dynamic
              constantInitializer
                fragment: #F5
                expression: expression_0
              superConstructorParameter: <null>
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::#0
''');
  }

  test_constructor_primary_formalParameter_super_requiredPositional() async {
    var library = await buildLibrary(r'''
extension type A(super.it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 11
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional hasImplicitType isFinal isOriginDeclaration super.it (nameOffset:23) (firstTokenOffset:17) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isFinal super.it
              firstFragment: #F5
              type: dynamic
              superConstructorParameter: <null>
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::#0
''');
  }

  test_constructor_primary_formalParameter_super_requiredPositional_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(super.it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 11
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional hasImplicitType isFinal isOriginDeclaration super.it (nameOffset:39) (firstTokenOffset:33) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isFinal super.it
              firstFragment: #F5
              type: dynamic
              superConstructorParameter: <null>
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::#0
''');
  }

  test_constructor_primary_formalParameters_none() async {
    var library = await buildLibrary(r'''
extension type A() {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 3
              typeName: A
              typeNameOffset: 15
          getters
            #F3 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::#0
''');
  }

  test_constructor_primary_formalParameters_none_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A() {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 3
              typeName: A
              typeNameOffset: 31
          getters
            #F3 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::#0
''');
  }

  test_constructor_primary_formalParameters_regular_optionalNamed_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A({int? a, int? b}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 19
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalNamed isDeclaring isFinal isOriginDeclaration this.a (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 optionalNamed isOriginDeclaration b (nameOffset:31) (firstTokenOffset:26) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed isDeclaring isFinal this.a
              firstFragment: #F5
              type: int?
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalNamed b
              firstFragment: #F6
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_regular_optionalNamed_optionalNamed_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A({int? a, int? b}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 19
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 optionalNamed isDeclaring isFinal isOriginDeclaration this.a (nameOffset:39) (firstTokenOffset:34) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 optionalNamed isOriginDeclaration b (nameOffset:47) (firstTokenOffset:42) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed isDeclaring isFinal this.a
              firstFragment: #F5
              type: int?
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalNamed b
              firstFragment: #F6
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_regular_optionalNamed_requiredNamed() async {
    var library = await buildLibrary(r'''
extension type A({int? a, required int b}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 27
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalNamed isDeclaring isFinal isOriginDeclaration this.a (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 requiredNamed isOriginDeclaration b (nameOffset:39) (firstTokenOffset:26) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed isDeclaring isFinal this.a
              firstFragment: #F5
              type: int?
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 requiredNamed b
              firstFragment: #F6
              type: int
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_regular_optionalPositional_optionalPositional() async {
    var library = await buildLibrary(r'''
extension type A([int? a, int? b]) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 19
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 optionalPositional isDeclaring isFinal isOriginDeclaration this.a (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 optionalPositional isOriginDeclaration b (nameOffset:31) (firstTokenOffset:26) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalPositional isDeclaring isFinal this.a
              firstFragment: #F5
              type: int?
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalPositional b
              firstFragment: #F6
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_regular_optionalPositional_optionalPositional_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A([int? a, int? b]) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 19
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 optionalPositional isDeclaring isFinal isOriginDeclaration this.a (nameOffset:39) (firstTokenOffset:34) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 optionalPositional isOriginDeclaration b (nameOffset:47) (firstTokenOffset:42) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 optionalPositional isDeclaring isFinal this.a
              firstFragment: #F5
              type: int?
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalPositional b
              firstFragment: #F6
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_regular_requiredNamed_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A({required int a, int? b}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 27
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredNamed isDeclaring isFinal isOriginDeclaration this.a (nameOffset:31) (firstTokenOffset:18) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 optionalNamed isOriginDeclaration b (nameOffset:39) (firstTokenOffset:34) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredNamed isDeclaring isFinal this.a
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalNamed b
              firstFragment: #F6
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_regular_requiredNamed_requiredNamed() async {
    var library = await buildLibrary(r'''
extension type A({required int a, required int b}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 35
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredNamed isDeclaring isFinal isOriginDeclaration this.a (nameOffset:31) (firstTokenOffset:18) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 requiredNamed isOriginDeclaration b (nameOffset:47) (firstTokenOffset:34) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredNamed isDeclaring isFinal this.a
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 requiredNamed b
              firstFragment: #F6
              type: int
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_regular_requiredPositional_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A(int a, {int? b}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 18
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.a (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 optionalNamed isOriginDeclaration b (nameOffset:30) (firstTokenOffset:25) (offset:30)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.a
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalNamed b
              firstFragment: #F6
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_regular_requiredPositional_optionalNamed_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int a, {int? b}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 18
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.a (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 optionalNamed isOriginDeclaration b (nameOffset:46) (firstTokenOffset:41) (offset:46)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.a
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalNamed b
              firstFragment: #F6
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_regular_requiredPositional_optionalPositional() async {
    var library = await buildLibrary(r'''
extension type A(int a, [int? b]) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 18
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.a (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 optionalPositional isOriginDeclaration b (nameOffset:30) (firstTokenOffset:25) (offset:30)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.a
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalPositional b
              firstFragment: #F6
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_regular_requiredPositional_optionalPositional_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int a, [int? b]) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 18
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.a (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 optionalPositional isOriginDeclaration b (nameOffset:46) (firstTokenOffset:41) (offset:46)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.a
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalPositional b
              firstFragment: #F6
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_regular_requiredPositional_requiredPositional() async {
    var library = await buildLibrary(r'''
extension type A(int a, int b) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 15
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.a (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 requiredPositional isOriginDeclaration b (nameOffset:28) (firstTokenOffset:24) (offset:28)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.a
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 requiredPositional b
              firstFragment: #F6
              type: int
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_regular_requiredPositional_requiredPositional_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int a, int b) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::a
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 15
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.a (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F6 requiredPositional isOriginDeclaration b (nameOffset:44) (firstTokenOffset:40) (offset:44)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F3 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::a
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.a
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 requiredPositional b
              firstFragment: #F6
              type: int
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_constructor_primary_formalParameters_trailingComma() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 9
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_formalParameters_trailingComma_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 9
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_missing() async {
    var library = await buildLibrary(r'''
extension type A {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 2
              typeName: A
              typeNameOffset: 15
          getters
            #F3 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::#0
''');
  }

  test_constructor_primary_named() async {
    var library = await buildLibrary(r'''
extension type A.name(int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary name (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::name
              codeOffset: 15
              codeLength: 14
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:26) (firstTokenOffset:22) (offset:26)
                  element: <testLibrary>::@extensionType::A::@constructor::name::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::name
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::name::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary name
          reference: <testLibrary>::@extensionType::A::@constructor::name
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_primary_scopes() async {
    var library = await buildLibrary(r'''
const foo = 0;

extension type E<@foo T>([@foo int it = foo]) {
  static const foo = 1;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::E
          typeParameters
            #F2 T (nameOffset:38) (firstTokenOffset:33) (offset:38)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @33
                  name: SimpleIdentifier
                    token: foo @34
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::E::@field::it
              inducedGetter: #F4
            #F5 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:79) (firstTokenOffset:79) (offset:79)
              element: <testLibrary>::@extensionType::E::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 1 @85
                  staticType: int
              inducedGetter: #F6
          constructors
            #F7 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::E::@constructor::new
              typeName: E
              typeNameOffset: 31
              formalParameters
                #F8 optionalPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:51) (firstTokenOffset:42) (offset:51)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
                  metadata
                    Annotation
                      atSign: @ @42
                      name: SimpleIdentifier
                        token: foo @43
                        element: <testLibrary>::@extensionType::E::@getter::foo
                        staticType: null
                      element: <testLibrary>::@extensionType::E::@getter::foo
                  initializer: expression_1
                    SimpleIdentifier
                      token: foo @56
                      element: <testLibrary>::@extensionType::E::@getter::foo
                      staticType: int
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::E::@getter::it
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:79)
              element: <testLibrary>::@extensionType::E::@getter::foo
              inducingVariable: #F5
      topLevelVariables
        #F9 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_2
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F10
      getters
        #F10 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F9
  extensionTypes
    isSimplyBounded extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @33
              name: SimpleIdentifier
                token: foo @34
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F3
          metadata
            Annotation
              atSign: @ @42
              name: SimpleIdentifier
                token: foo @43
                element: <testLibrary>::@extensionType::E::@getter::foo
                staticType: null
              element: <testLibrary>::@extensionType::E::@getter::foo
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
          reference: <testLibrary>::@extensionType::E::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@extensionType::E::@getter::foo
      constructors
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F7
          formalParameters
            #E1 optionalPositional hasDefaultValue isDeclaring isFinal this.it
              firstFragment: #F8
              type: int
              metadata
                Annotation
                  atSign: @ @42
                  name: SimpleIdentifier
                    token: foo @43
                    element: <testLibrary>::@extensionType::E::@getter::foo
                    staticType: null
                  element: <testLibrary>::@extensionType::E::@getter::foo
              constantInitializer
                fragment: #F8
                expression: expression_1
              field: <testLibrary>::@extensionType::E::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::E::@getter::foo
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::foo
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F9
      type: int
      constantInitializer
        fragment: #F9
        expression: expression_2
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_constructor_primary_typeParameters() async {
    var library = await buildLibrary(r'''
extension type E<T extends U, U extends num>(T it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::E
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
            #F3 U (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: #E1 U
          fields
            #F4 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::E::@field::it
              inducedGetter: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::E::@constructor::new
              typeName: E
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:47) (firstTokenOffset:45) (offset:47)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
          getters
            #F5 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::E::@getter::it
              inducingVariable: #F4
  extensionTypes
    extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: U
        #E1 U
          firstFragment: #F3
          bound: num
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: T
      fields
        hasEnclosingTypeParameterReference isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F4
          type: T
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
      constructors
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E2 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: T
              field: <testLibrary>::@extensionType::E::@field::it
      getters
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F5
          returnType: T
          variable: <testLibrary>::@extensionType::E::@field::it
''');
  }

  test_constructor_secondary_augmentation_add_named() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

augment extension type A(int it) {
  A.named();
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F10
        #F2 isAugmentation extension type A (nameOffset:52) (firstTokenOffset:29) (offset:52)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F3
          constructors
            #F9 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:52) (offset:52)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 52
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:58) (firstTokenOffset:54) (offset:58)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F6
            #F11 isOriginDeclaration named (nameOffset:68) (firstTokenOffset:66) (offset:68)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 66
              periodOffset: 67
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F11
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_augmentation_add_named_generic() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {}

augment extension type A<T>(int it) {
  A.named(T a);
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F6
              nextFragment: #F7
          constructors
            #F8 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F10
              nextFragment: #F11
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              nextFragment: #F12
        #F2 isAugmentation extension type A (nameOffset:55) (firstTokenOffset:32) (offset:55)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:57) (firstTokenOffset:57) (offset:57)
              element: #E0 T
              previousFragment: #F3
          fields
            #F7 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F12
              previousFragment: #F5
          constructors
            #F11 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:55) (offset:55)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 55
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:64) (firstTokenOffset:60) (offset:64)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F8
            #F13 isOriginDeclaration named (nameOffset:74) (firstTokenOffset:72) (offset:74)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 72
              periodOffset: 73
              formalParameters
                #F14 requiredPositional isOriginDeclaration a (nameOffset:82) (firstTokenOffset:80) (offset:82)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::a
          getters
            #F12 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              previousFragment: #F6
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F9
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F13
          formalParameters
            #E2 requiredPositional a
              firstFragment: #F14
              type: T
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_augmentation_add_unnamed_hasNamed() async {
    var library = await buildLibrary(r'''
extension type A.named(int it) {}

augment extension type A.named(int it) {
  A();
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary named (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F10
        #F2 isAugmentation extension type A (nameOffset:58) (firstTokenOffset:35) (offset:58)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F3
          constructors
            #F9 isAugmentation isComplete isOriginDeclaration isPrimary named (nameOffset:60) (firstTokenOffset:58) (offset:60)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 58
              periodOffset: 59
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:70) (firstTokenOffset:66) (offset:70)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F6
            #F11 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:78) (offset:78)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 78
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::named
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F11
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_augmentation_chain_isComplete_factory() async {
    var library = await buildLibrary(r'''
extension type A.named(int it) {
  factory A();
}

augment extension type A.named(int it) {
  augment factory A() => A.named(0);
}

augment extension type A.named(int it) {
  augment factory A();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary named (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
            #F10 isFactory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:35) (offset:43)
              element: <testLibrary>::@extensionType::A::@constructor::new
              factoryKeywordOffset: 35
              typeName: A
              typeNameOffset: 43
              nextFragment: #F11
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F12
        #F2 isAugmentation extension type A (nameOffset:74) (firstTokenOffset:51) (offset:74)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F13
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F12
              previousFragment: #F3
              nextFragment: #F14
          constructors
            #F9 isAugmentation isComplete isOriginDeclaration isPrimary named (nameOffset:76) (firstTokenOffset:74) (offset:76)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 74
              periodOffset: 75
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:86) (firstTokenOffset:82) (offset:86)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
                  previousFragment: #F7
                  nextFragment: #F15
              nextFragment: #F16
              previousFragment: #F6
            #F11 isAugmentation isComplete isFactory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:94) (offset:110)
              element: <testLibrary>::@extensionType::A::@constructor::new
              factoryKeywordOffset: 102
              typeName: A
              typeNameOffset: 110
              nextFragment: #F17
              previousFragment: #F10
          getters
            #F12 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
              nextFragment: #F18
        #F13 isAugmentation extension type A (nameOffset:155) (firstTokenOffset:132) (offset:155)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F14 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:155)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F18
              previousFragment: #F5
          constructors
            #F16 isAugmentation isComplete isOriginDeclaration isPrimary named (nameOffset:157) (firstTokenOffset:155) (offset:157)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 155
              periodOffset: 156
              formalParameters
                #F15 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:167) (firstTokenOffset:163) (offset:167)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F9
            #F17 isAugmentation isFactory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:175) (offset:191)
              element: <testLibrary>::@extensionType::A::@constructor::new
              factoryKeywordOffset: 183
              typeName: A
              typeNameOffset: 191
              previousFragment: #F11
          getters
            #F18 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:155)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F14
              previousFragment: #F12
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::named
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isFactory isOriginDeclaration new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F10
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_factory() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  factory A(int it) => A(it);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F6 isComplete isFactory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::new#1
              factoryKeywordOffset: 29
              typeName: A
              typeNameOffset: 37
              formalParameters
                #F7 requiredPositional isOriginDeclaration it (nameOffset:43) (firstTokenOffset:39) (offset:43)
                  element: <testLibrary>::@extensionType::A::@constructor::new#1::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isFactory isOriginDeclaration new
          reference: <testLibrary>::@extensionType::A::@constructor::new#1
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional it
              firstFragment: #F7
              type: int
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_factory_named() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  factory A.named(int it) => A(it);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F6 isComplete isFactory isOriginDeclaration named (nameOffset:39) (firstTokenOffset:29) (offset:39)
              element: <testLibrary>::@extensionType::A::@constructor::named
              factoryKeywordOffset: 29
              typeName: A
              typeNameOffset: 37
              periodOffset: 38
              formalParameters
                #F7 requiredPositional isOriginDeclaration it (nameOffset:49) (firstTokenOffset:45) (offset:49)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isFactory isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional it
              firstFragment: #F7
              type: int
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_factoryHead_named() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  factory named(int it) => A(it);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F6 isComplete isFactory isOriginDeclaration named (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::named
              factoryKeywordOffset: 29
              typeName: null
              formalParameters
                #F7 requiredPositional isOriginDeclaration it (nameOffset:47) (firstTokenOffset:43) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isFactory isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional it
              firstFragment: #F7
              type: int
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_factoryHead_unnamed() async {
    var library = await buildLibrary(r'''
extension type A.primary(int it) {
  factory(int it) => A.primary(it);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary primary (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::primary
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@extensionType::A::@constructor::primary::@formalParameter::it
            #F6 isComplete isFactory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::new
              factoryKeywordOffset: 37
              typeName: null
              formalParameters
                #F7 requiredPositional isOriginDeclaration it (nameOffset:49) (firstTokenOffset:45) (offset:49)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::primary
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::primary::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary primary
          reference: <testLibrary>::@extensionType::A::@constructor::primary
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isFactory isOriginDeclaration new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional it
              firstFragment: #F7
              type: int
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_formalParameter_field_optionalNamed_private() async {
    var library = await buildLibrary(r'''
extension type A(int? _it) {
  A.named({this._it});
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter isPromotable _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::_it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this._it (nameOffset:22) (firstTokenOffset:17) (offset:22)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_it
            #F6 isComplete isOriginDeclaration named (nameOffset:33) (firstTokenOffset:31) (offset:33)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 31
              periodOffset: 32
              formalParameters
                #F7 optionalNamed hasImplicitType isFinal isOriginDeclaration this.it (nameOffset:45) (firstTokenOffset:40) (offset:45)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::_it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::_it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter isPromotable _it
          reference: <testLibrary>::@extensionType::A::@field::_it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::_it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this._it
              firstFragment: #F5
              type: int?
              field: <testLibrary>::@extensionType::A::@field::_it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
          formalParameters
            #E1 optionalNamed hasImplicitType isFinal this.it
              firstFragment: #F7
              type: int?
              privateName: _it
              field: <testLibrary>::@extensionType::A::@field::_it
      getters
        isExtensionTypeMember isOriginVariable _it
          reference: <testLibrary>::@extensionType::A::@getter::_it
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::_it
''');
  }

  test_constructor_secondary_formalParameter_field_optionalNamed_private_noCorrespondingPublic() async {
    var library = await buildLibrary(r'''
extension type A(int? _123) {
  A.named({this._123});
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter isPromotable _123 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::_123
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this._123 (nameOffset:22) (firstTokenOffset:17) (offset:22)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_123
            #F6 isComplete isOriginDeclaration named (nameOffset:34) (firstTokenOffset:32) (offset:34)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 32
              periodOffset: 33
              formalParameters
                #F7 optionalNamed hasImplicitType isFinal isOriginDeclaration this._123 (nameOffset:46) (firstTokenOffset:41) (offset:46)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::_123
          getters
            #F3 isComplete isOriginVariable _123 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::_123
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::_123
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter isPromotable _123
          reference: <testLibrary>::@extensionType::A::@field::_123
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::_123
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_123
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this._123
              firstFragment: #F5
              type: int?
              field: <testLibrary>::@extensionType::A::@field::_123
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
          formalParameters
            #E1 optionalNamed hasImplicitType isFinal this._123
              firstFragment: #F7
              type: int?
              field: <testLibrary>::@extensionType::A::@field::_123
      getters
        isExtensionTypeMember isOriginVariable _123
          reference: <testLibrary>::@extensionType::A::@getter::_123
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::_123
''');
  }

  test_constructor_secondary_formalParameter_field_requiredNamed_private() async {
    var library = await buildLibrary(r'''
extension type A(int? _it) {
  A.named({required this._it});
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter isPromotable _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::_it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this._it (nameOffset:22) (firstTokenOffset:17) (offset:22)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_it
            #F6 isComplete isOriginDeclaration named (nameOffset:33) (firstTokenOffset:31) (offset:33)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 31
              periodOffset: 32
              formalParameters
                #F7 requiredNamed hasImplicitType isFinal isOriginDeclaration this.it (nameOffset:54) (firstTokenOffset:40) (offset:54)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::_it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::_it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter isPromotable _it
          reference: <testLibrary>::@extensionType::A::@field::_it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::_it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this._it
              firstFragment: #F5
              type: int?
              field: <testLibrary>::@extensionType::A::@field::_it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
          formalParameters
            #E1 requiredNamed hasImplicitType isFinal this.it
              firstFragment: #F7
              type: int?
              privateName: _it
              field: <testLibrary>::@extensionType::A::@field::_it
      getters
        isExtensionTypeMember isOriginVariable _it
          reference: <testLibrary>::@extensionType::A::@getter::_it
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::_it
''');
  }

  test_constructor_secondary_formalParameter_field_requiredPositional() async {
    var library = await buildLibrary(r'''
extension type A(num it) {
  A.named(this.it);
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F6 isComplete isOriginDeclaration named (nameOffset:31) (firstTokenOffset:29) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 29
              periodOffset: 30
              formalParameters
                #F7 requiredPositional hasImplicitType isFinal isOriginDeclaration this.it (nameOffset:42) (firstTokenOffset:37) (offset:42)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: num
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: num
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional hasImplicitType isFinal this.it
              firstFragment: #F7
              type: num
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: num
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_formalParameter_field_requiredPositional_fieldTyped_formalTyped() async {
    var library = await buildLibrary(r'''
extension type A(num it) {
  A.named(int this.it);
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F6 isComplete isOriginDeclaration named (nameOffset:31) (firstTokenOffset:29) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 29
              periodOffset: 30
              formalParameters
                #F7 requiredPositional isFinal isOriginDeclaration this.it (nameOffset:46) (firstTokenOffset:37) (offset:46)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: num
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: num
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: num
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_initializers_field() async {
    var library = await buildLibrary(r'''
extension type A(num it) {
  const A.named(int a) : it = a;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F6 isComplete isConst isOriginDeclaration named (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 35
              periodOffset: 36
              formalParameters
                #F7 requiredPositional isOriginDeclaration a (nameOffset:47) (firstTokenOffset:43) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::a
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: num
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: num
              field: <testLibrary>::@extensionType::A::@field::it
        isConst isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F7
              type: int
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: it @52
                element: <testLibrary>::@extensionType::A::@field::it
                staticType: null
              equals: = @55
              expression: SimpleIdentifier
                token: a @57
                element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::a
                staticType: int
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: num
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_newHead_named() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  new named(this.it);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F6 isComplete isOriginDeclaration named (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@extensionType::A::@constructor::named
              newKeywordOffset: 29
              typeName: null
              formalParameters
                #F7 requiredPositional hasImplicitType isFinal isOriginDeclaration this.it (nameOffset:44) (firstTokenOffset:39) (offset:44)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional hasImplicitType isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_newHead_named_const() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  const new named(this.it);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F6 isComplete isConst isOriginDeclaration named (nameOffset:39) (firstTokenOffset:29) (offset:39)
              element: <testLibrary>::@extensionType::A::@constructor::named
              newKeywordOffset: 35
              typeName: null
              formalParameters
                #F7 requiredPositional hasImplicitType isFinal isOriginDeclaration this.it (nameOffset:50) (firstTokenOffset:45) (offset:50)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isConst isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional hasImplicitType isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_newHead_unnamed() async {
    var library = await buildLibrary(r'''
extension type A.primary(int it) {
  new(this.it);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary primary (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::primary
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@extensionType::A::@constructor::primary::@formalParameter::it
            #F6 isComplete isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::new
              newKeywordOffset: 37
              typeName: null
              formalParameters
                #F7 requiredPositional hasImplicitType isFinal isOriginDeclaration this.it (nameOffset:46) (firstTokenOffset:41) (offset:46)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::primary
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::primary::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary primary
          reference: <testLibrary>::@extensionType::A::@constructor::primary
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional hasImplicitType isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_secondary_newHead_unnamed_const() async {
    var library = await buildLibrary(r'''
extension type A.primary(int it) {
  const new(this.it);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary primary (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::primary
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@extensionType::A::@constructor::primary::@formalParameter::it
            #F6 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::new
              newKeywordOffset: 43
              typeName: null
              formalParameters
                #F7 requiredPositional hasImplicitType isFinal isOriginDeclaration this.it (nameOffset:52) (firstTokenOffset:47) (offset:52)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::primary
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::primary::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary primary
          reference: <testLibrary>::@extensionType::A::@constructor::primary
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isConst isExtensionTypeMember isOriginDeclaration new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional hasImplicitType isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_allSupertypes() async {
    var library = await buildLibrary(r'''
extension type A(int? it) {}

extension type B(int it) implements A, num {}
''');

    configuration
      ..withConstructors = false
      ..withAllSupertypes = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
        #F4 extension type B (nameOffset:45) (firstTokenOffset:30) (offset:45)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@extensionType::B::@field::it
              inducedGetter: #F6
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@extensionType::B::@getter::it
              inducingVariable: #F5
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      interfaces
        A
        num
      allSupertypes
        A
        Comparable<num>
        Object
        num
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_extensionType_augmentation_chain_noIntroductoryDeclaration() async {
    var library = await buildLibrary(r'''
augment extension type A {
  void foo1() {}
}

augment extension type A {
  void foo2() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 isAugmentation extension type A (nameOffset:23) (firstTokenOffset:0) (offset:23)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F4
          constructors
            #F5 isConst isOriginExtensionTypeRecovery isPrimary new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F3
          methods
            #F6 isComplete isOriginDeclaration foo1 (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo1
        #F2 isAugmentation extension type A (nameOffset:70) (firstTokenOffset:47) (offset:70)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          methods
            #F7 isComplete isOriginDeclaration foo2 (nameOffset:81) (firstTokenOffset:76) (offset:81)
              element: <testLibrary>::@extensionType::A::@method::foo2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: dynamic
      fields
        hasImplicitType isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F3
          type: dynamic
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isConst isExtensionTypeMember isOriginExtensionTypeRecovery isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@extensionType::A::@field::#0
      methods
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@method::foo1
          firstFragment: #F6
          returnType: void
        isExtensionTypeMember isOriginDeclaration foo2
          reference: <testLibrary>::@extensionType::A::@method::foo2
          firstFragment: #F7
          returnType: void
''');
  }

  test_extensionType_augmentation_chain_noIntroductoryDeclaration_emptyThenSecondaryConstructor() async {
    var library = await buildLibrary(r'''
augment extension type A {}

augment extension type A {
  A.named();
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 isAugmentation extension type A (nameOffset:23) (firstTokenOffset:0) (offset:23)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F4
          constructors
            #F5 isConst isOriginExtensionTypeRecovery isPrimary new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F3
        #F2 isAugmentation extension type A (nameOffset:52) (firstTokenOffset:29) (offset:52)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          constructors
            #F6 isOriginDeclaration named (nameOffset:60) (firstTokenOffset:58) (offset:60)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 58
              periodOffset: 59
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: dynamic
      fields
        hasImplicitType isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F3
          type: dynamic
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isConst isExtensionTypeMember isOriginExtensionTypeRecovery isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F6
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@extensionType::A::@field::#0
''');
  }

  test_extensionType_augmentation_chain_noIntroductoryDeclaration_emptyThenStaticField() async {
    var library = await buildLibrary(r'''
augment extension type A {}

augment extension type A {
  static int foo = 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 isAugmentation extension type A (nameOffset:23) (firstTokenOffset:0) (offset:23)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F4
          constructors
            #F5 isConst isOriginExtensionTypeRecovery isPrimary new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F3
        #F2 isAugmentation extension type A (nameOffset:52) (firstTokenOffset:29) (offset:52)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F6 hasInitializer isOriginDeclaration isStatic foo (nameOffset:69) (firstTokenOffset:69) (offset:69)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F7
              inducedSetter: #F8
          getters
            #F7 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F6
          setters
            #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F6
              formalParameters
                #F9 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: dynamic
      fields
        hasImplicitType isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F3
          type: dynamic
          getter: <testLibrary>::@extensionType::A::@getter::#1
        hasInitializer isOriginDeclaration isStatic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isConst isExtensionTypeMember isOriginExtensionTypeRecovery isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@extensionType::A::@field::#0
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_extensionType_augmentation_chain_noIntroductoryDeclaration_primaryConstructor() async {
    var library = await buildLibrary(r'''
augment extension type A(int it) {
  void foo1() {}
}

augment extension type A(int it) {
  void foo2() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 isAugmentation extension type A (nameOffset:23) (firstTokenOffset:0) (offset:23)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          constructors
            #F6 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 23
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F4 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F10
          methods
            #F11 isComplete isOriginDeclaration foo1 (nameOffset:42) (firstTokenOffset:37) (offset:42)
              element: <testLibrary>::@extensionType::A::@method::foo1
        #F2 isAugmentation extension type A (nameOffset:78) (firstTokenOffset:55) (offset:78)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F3
          constructors
            #F9 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:78) (offset:78)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 78
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:84) (firstTokenOffset:80) (offset:84)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F6
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
          methods
            #F12 isComplete isOriginDeclaration foo2 (nameOffset:97) (firstTokenOffset:92) (offset:97)
              element: <testLibrary>::@extensionType::A::@method::foo2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@method::foo1
          firstFragment: #F11
          returnType: void
        isExtensionTypeMember isOriginDeclaration foo2
          reference: <testLibrary>::@extensionType::A::@method::foo2
          firstFragment: #F12
          returnType: void
''');
  }

  test_extensionType_augmentation_chain_noIntroductoryDeclaration_secondaryConstructor() async {
    var library = await buildLibrary(r'''
augment extension type A {
  A.named();
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 isAugmentation extension type A (nameOffset:23) (firstTokenOffset:0) (offset:23)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F3
          constructors
            #F4 isConst isOriginExtensionTypeRecovery isPrimary new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
            #F5 isOriginDeclaration named (nameOffset:31) (firstTokenOffset:29) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 29
              periodOffset: 30
          getters
            #F3 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: dynamic
      fields
        hasImplicitType isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isConst isExtensionTypeMember isOriginExtensionTypeRecovery isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@extensionType::A::@field::#0
''');
  }

  test_extensionType_augmentation_chain_noIntroductoryDeclaration_secondaryConstructor_unnamed() async {
    var library = await buildLibrary(r'''
augment extension type A {
  A();
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 isAugmentation extension type A (nameOffset:23) (firstTokenOffset:0) (offset:23)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F3
          constructors
            #F4 isConst isOriginExtensionTypeRecovery isPrimary new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
            #F5 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@extensionType::A::@constructor::new#1
              typeName: A
              typeNameOffset: 29
          getters
            #F3 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: dynamic
      fields
        hasImplicitType isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@extensionType::A::@getter::#1
      constructors
        isConst isExtensionTypeMember isOriginExtensionTypeRecovery isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
        isExtensionTypeMember isOriginDeclaration new
          reference: <testLibrary>::@extensionType::A::@constructor::new#1
          firstFragment: #F5
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@extensionType::A::@field::#0
''');
  }

  test_extensionType_augmentation_chain_noIntroductoryDeclaration_staticField() async {
    var library = await buildLibrary(r'''
augment extension type A {
  static int foo = 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 isAugmentation extension type A (nameOffset:23) (firstTokenOffset:0) (offset:23)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 hasImplicitType isFinal isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@field::#0
              inducedGetter: #F3
            #F4 hasInitializer isOriginDeclaration isStatic foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F5
              inducedSetter: #F6
          constructors
            #F7 isConst isOriginExtensionTypeRecovery isPrimary new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@getter::#1
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F4
          setters
            #F6 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F4
              formalParameters
                #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::#0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: dynamic
      fields
        hasImplicitType isFinal isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::#0
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@extensionType::A::@getter::#1
        hasInitializer isOriginDeclaration isStatic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isConst isExtensionTypeMember isOriginExtensionTypeRecovery isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::#1
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@extensionType::A::@field::#0
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_extensionType_augmentation_chain_twoDeclarations() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

augment extension type A(int it) {}

augment extension type A(int it) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F10
        #F2 isAugmentation extension type A (nameOffset:52) (firstTokenOffset:29) (offset:52)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F11
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F3
              nextFragment: #F12
          constructors
            #F9 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:52) (offset:52)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 52
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:58) (firstTokenOffset:54) (offset:58)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
                  nextFragment: #F13
              nextFragment: #F14
              previousFragment: #F6
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
              nextFragment: #F15
        #F11 isAugmentation extension type A (nameOffset:89) (firstTokenOffset:66) (offset:89)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F12 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F15
              previousFragment: #F5
          constructors
            #F14 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:89) (offset:89)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 89
              formalParameters
                #F13 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:95) (firstTokenOffset:91) (offset:95)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F9
          getters
            #F15 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F12
              previousFragment: #F10
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
  exportEntries
    declared <testLibrary>::@extensionType::A
  exportNamespace
    A: <testLibrary>::@extensionType::A
''');
  }

  test_extensionType_augmentation_sameName_class_class() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

augment class A {}

augment class A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 isAugmentation class A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::A
          nextFragment: #F2
        #F2 isAugmentation class A (nameOffset:63) (firstTokenOffset:49) (offset:63)
          element: <testLibrary>::@class::A
          previousFragment: #F1
      extensionTypes
        #F3 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F4 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F5
          getters
            #F5 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F4
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      previousFragmentOfDifferentKind: #F3
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_augmentation_sameName_class_extensionType() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

augment class A {}

augment extension type A(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 isAugmentation class A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::A
      extensionTypes
        #F2 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
        #F5 isAugmentation extension type A (nameOffset:72) (firstTokenOffset:49) (offset:72)
          element: <testLibrary>::@extensionType::A#1
          fields
            #F6 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@extensionType::A#1::@field::it
              inducedGetter: #F7
          getters
            #F7 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@extensionType::A#1::@getter::it
              inducingVariable: #F6
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      previousFragmentOfDifferentKind: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F2
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
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A#1
      firstFragment: #F5
      previousFragmentOfDifferentKind: #F1
      representation: <testLibrary>::@extensionType::A#1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A#1::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A#1::@field::it
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A#1::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A#1::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A#1::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A#1::@field::it
''');
  }

  test_extensionType_documented() async {
    var library = await buildLibrary(r'''
/// Docs
extension type A(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:24) (firstTokenOffset:0) (offset:24)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:24) (offset:24)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 24
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:30) (firstTokenOffset:26) (offset:30)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      documentationComment: /// Docs
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_interfaces_augmentation_add() async {
    configuration.withConstructors = false;
    var library = await buildLibrary(r'''
extension type A(int it) implements I1 {}
extension type I1(int it) {}

augment extension type A(int it) implements I2 {}
extension type I2(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F6
        #F7 extension type I1 (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@extensionType::I1
          fields
            #F8 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::I1::@field::it
              inducedGetter: #F9
          getters
            #F9 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::I1::@getter::it
              inducingVariable: #F8
        #F2 isAugmentation extension type A (nameOffset:95) (firstTokenOffset:72) (offset:95)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F6
              previousFragment: #F3
          getters
            #F6 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
        #F10 extension type I2 (nameOffset:137) (firstTokenOffset:122) (offset:137)
          element: <testLibrary>::@extensionType::I2
          fields
            #F11 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:137)
              element: <testLibrary>::@extensionType::I2::@field::it
              inducedGetter: #F12
          getters
            #F12 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:137)
              element: <testLibrary>::@extensionType::I2::@getter::it
              inducingVariable: #F11
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        I1
        I2
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: #F7
      representation: <testLibrary>::@extensionType::I1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I1::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I1::@field::it
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@extensionType::I1::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I1::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::I1::@field::it
    isSimplyBounded extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: #F10
      representation: <testLibrary>::@extensionType::I2::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I2::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I2::@field::it
          firstFragment: #F11
          type: int
          getter: <testLibrary>::@extensionType::I2::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I2::@getter::it
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@extensionType::I2::@field::it
''');
  }

  test_extensionType_interfaces_augmentation_add_chain() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements I1 {}
extension type I1(int it) {}

augment extension type A(int it) implements I2 {}
extension type I2(int it) {}

augment extension type A(int it) implements I3 {}
extension type I3(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F10
        #F11 extension type I1 (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@extensionType::I1
          fields
            #F12 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::I1::@field::it
              inducedGetter: #F13
          constructors
            #F14 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:57) (offset:57)
              element: <testLibrary>::@extensionType::I1::@constructor::new
              typeName: I1
              typeNameOffset: 57
              formalParameters
                #F15 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:64) (firstTokenOffset:60) (offset:64)
                  element: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
          getters
            #F13 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::I1::@getter::it
              inducingVariable: #F12
        #F2 isAugmentation extension type A (nameOffset:95) (firstTokenOffset:72) (offset:95)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F16
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F3
              nextFragment: #F17
          constructors
            #F9 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:95) (offset:95)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 95
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:101) (firstTokenOffset:97) (offset:101)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
                  nextFragment: #F18
              nextFragment: #F19
              previousFragment: #F6
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
              nextFragment: #F20
        #F21 extension type I2 (nameOffset:137) (firstTokenOffset:122) (offset:137)
          element: <testLibrary>::@extensionType::I2
          fields
            #F22 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:137)
              element: <testLibrary>::@extensionType::I2::@field::it
              inducedGetter: #F23
          constructors
            #F24 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:137) (offset:137)
              element: <testLibrary>::@extensionType::I2::@constructor::new
              typeName: I2
              typeNameOffset: 137
              formalParameters
                #F25 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:144) (firstTokenOffset:140) (offset:144)
                  element: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
          getters
            #F23 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:137)
              element: <testLibrary>::@extensionType::I2::@getter::it
              inducingVariable: #F22
        #F16 isAugmentation extension type A (nameOffset:175) (firstTokenOffset:152) (offset:175)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F17 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:175)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F20
              previousFragment: #F5
          constructors
            #F19 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:175) (offset:175)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 175
              formalParameters
                #F18 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:181) (firstTokenOffset:177) (offset:181)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F9
          getters
            #F20 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:175)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F17
              previousFragment: #F10
        #F26 extension type I3 (nameOffset:217) (firstTokenOffset:202) (offset:217)
          element: <testLibrary>::@extensionType::I3
          fields
            #F27 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:217)
              element: <testLibrary>::@extensionType::I3::@field::it
              inducedGetter: #F28
          constructors
            #F29 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:217) (offset:217)
              element: <testLibrary>::@extensionType::I3::@constructor::new
              typeName: I3
              typeNameOffset: 217
              formalParameters
                #F30 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:224) (firstTokenOffset:220) (offset:224)
                  element: <testLibrary>::@extensionType::I3::@constructor::new::@formalParameter::it
          getters
            #F28 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:217)
              element: <testLibrary>::@extensionType::I3::@getter::it
              inducingVariable: #F27
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        I1
        I2
        I3
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
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: #F11
      representation: <testLibrary>::@extensionType::I1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I1::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I1::@field::it
          firstFragment: #F12
          type: int
          getter: <testLibrary>::@extensionType::I1::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I1::@constructor::new
          firstFragment: #F14
          formalParameters
            #E1 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F15
              type: int
              field: <testLibrary>::@extensionType::I1::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I1::@getter::it
          firstFragment: #F13
          returnType: int
          variable: <testLibrary>::@extensionType::I1::@field::it
    isSimplyBounded extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: #F21
      representation: <testLibrary>::@extensionType::I2::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I2::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I2::@field::it
          firstFragment: #F22
          type: int
          getter: <testLibrary>::@extensionType::I2::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I2::@constructor::new
          firstFragment: #F24
          formalParameters
            #E2 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F25
              type: int
              field: <testLibrary>::@extensionType::I2::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I2::@getter::it
          firstFragment: #F23
          returnType: int
          variable: <testLibrary>::@extensionType::I2::@field::it
    isSimplyBounded extension type I3
      reference: <testLibrary>::@extensionType::I3
      firstFragment: #F26
      representation: <testLibrary>::@extensionType::I3::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I3::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I3::@field::it
          firstFragment: #F27
          type: int
          getter: <testLibrary>::@extensionType::I3::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I3::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I3::@constructor::new
          firstFragment: #F29
          formalParameters
            #E3 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F30
              type: int
              field: <testLibrary>::@extensionType::I3::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I3::@getter::it
          firstFragment: #F28
          returnType: int
          variable: <testLibrary>::@extensionType::I3::@field::it
''');
  }

  test_extensionType_interfaces_augmentation_add_generic() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) implements I1 {}
extension type I1(int it) {}

augment extension type A<T>(int it) implements I2<T> {}
extension type I2<E>(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F6
              nextFragment: #F7
          constructors
            #F8 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F10
              nextFragment: #F11
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              nextFragment: #F12
        #F13 extension type I1 (nameOffset:60) (firstTokenOffset:45) (offset:60)
          element: <testLibrary>::@extensionType::I1
          fields
            #F14 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: <testLibrary>::@extensionType::I1::@field::it
              inducedGetter: #F15
          constructors
            #F16 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:60) (offset:60)
              element: <testLibrary>::@extensionType::I1::@constructor::new
              typeName: I1
              typeNameOffset: 60
              formalParameters
                #F17 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:67) (firstTokenOffset:63) (offset:67)
                  element: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
          getters
            #F15 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: <testLibrary>::@extensionType::I1::@getter::it
              inducingVariable: #F14
        #F2 isAugmentation extension type A (nameOffset:98) (firstTokenOffset:75) (offset:98)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:100) (firstTokenOffset:100) (offset:100)
              element: #E0 T
              previousFragment: #F3
          fields
            #F7 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F12
              previousFragment: #F5
          constructors
            #F11 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:98) (offset:98)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 98
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:107) (firstTokenOffset:103) (offset:107)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F8
          getters
            #F12 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              previousFragment: #F6
        #F18 extension type I2 (nameOffset:146) (firstTokenOffset:131) (offset:146)
          element: <testLibrary>::@extensionType::I2
          typeParameters
            #F19 E (nameOffset:149) (firstTokenOffset:149) (offset:149)
              element: #E1 E
          fields
            #F20 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:146)
              element: <testLibrary>::@extensionType::I2::@field::it
              inducedGetter: #F21
          constructors
            #F22 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:146) (offset:146)
              element: <testLibrary>::@extensionType::I2::@constructor::new
              typeName: I2
              typeNameOffset: 146
              formalParameters
                #F23 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:156) (firstTokenOffset:152) (offset:156)
                  element: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
          getters
            #F21 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:146)
              element: <testLibrary>::@extensionType::I2::@getter::it
              inducingVariable: #F20
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        I1
        I2<T>
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E2 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F9
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: #F13
      representation: <testLibrary>::@extensionType::I1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I1::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I1::@field::it
          firstFragment: #F14
          type: int
          getter: <testLibrary>::@extensionType::I1::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I1::@constructor::new
          firstFragment: #F16
          formalParameters
            #E3 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F17
              type: int
              field: <testLibrary>::@extensionType::I1::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I1::@getter::it
          firstFragment: #F15
          returnType: int
          variable: <testLibrary>::@extensionType::I1::@field::it
    isSimplyBounded extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: #F18
      typeParameters
        #E1 E
          firstFragment: #F19
      representation: <testLibrary>::@extensionType::I2::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I2::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I2::@field::it
          firstFragment: #F20
          type: int
          getter: <testLibrary>::@extensionType::I2::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
      constructors
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I2::@constructor::new
          firstFragment: #F22
          formalParameters
            #E4 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F23
              type: int
              field: <testLibrary>::@extensionType::I2::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I2::@getter::it
          firstFragment: #F21
          returnType: int
          variable: <testLibrary>::@extensionType::I2::@field::it
''');
  }

  test_extensionType_interfaces_augmentation_add_generic_mismatch() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) implements I1 {}
extension type I1(int it) {}

augment extension type A<T, U>(int it) implements I2<T> {}
extension type I2<E>(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
            #F5 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: #E1 U
              nextFragment: #F6
          fields
            #F7 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F8
              nextFragment: #F9
          constructors
            #F10 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F11 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F12
              nextFragment: #F13
          getters
            #F8 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              nextFragment: #F14
        #F15 extension type I1 (nameOffset:60) (firstTokenOffset:45) (offset:60)
          element: <testLibrary>::@extensionType::I1
          fields
            #F16 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: <testLibrary>::@extensionType::I1::@field::it
              inducedGetter: #F17
          constructors
            #F18 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:60) (offset:60)
              element: <testLibrary>::@extensionType::I1::@constructor::new
              typeName: I1
              typeNameOffset: 60
              formalParameters
                #F19 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:67) (firstTokenOffset:63) (offset:67)
                  element: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
          getters
            #F17 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: <testLibrary>::@extensionType::I1::@getter::it
              inducingVariable: #F16
        #F2 isAugmentation extension type A (nameOffset:98) (firstTokenOffset:75) (offset:98)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:100) (firstTokenOffset:100) (offset:100)
              element: #E0 T
              previousFragment: #F3
            #F6 U (nameOffset:103) (firstTokenOffset:103) (offset:103)
              element: #E1 U
              previousFragment: #F5
          fields
            #F9 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F14
              previousFragment: #F7
          constructors
            #F13 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:98) (offset:98)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 98
              formalParameters
                #F12 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:110) (firstTokenOffset:106) (offset:110)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F11
              previousFragment: #F10
          getters
            #F14 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F9
              previousFragment: #F8
        #F20 extension type I2 (nameOffset:149) (firstTokenOffset:134) (offset:149)
          element: <testLibrary>::@extensionType::I2
          typeParameters
            #F21 E (nameOffset:152) (firstTokenOffset:152) (offset:152)
              element: #E2 E
          fields
            #F22 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:149)
              element: <testLibrary>::@extensionType::I2::@field::it
              inducedGetter: #F23
          constructors
            #F24 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:149) (offset:149)
              element: <testLibrary>::@extensionType::I2::@constructor::new
              typeName: I2
              typeNameOffset: 149
              formalParameters
                #F25 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:159) (firstTokenOffset:155) (offset:159)
                  element: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
          getters
            #F23 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:149)
              element: <testLibrary>::@extensionType::I2::@getter::it
              inducingVariable: #F22
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        I1
        I2<T>
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F10
          formalParameters
            #E3 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F11
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: #F15
      representation: <testLibrary>::@extensionType::I1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I1::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I1::@field::it
          firstFragment: #F16
          type: int
          getter: <testLibrary>::@extensionType::I1::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I1::@constructor::new
          firstFragment: #F18
          formalParameters
            #E4 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F19
              type: int
              field: <testLibrary>::@extensionType::I1::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I1::@getter::it
          firstFragment: #F17
          returnType: int
          variable: <testLibrary>::@extensionType::I1::@field::it
    isSimplyBounded extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: #F20
      typeParameters
        #E2 E
          firstFragment: #F21
      representation: <testLibrary>::@extensionType::I2::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I2::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I2::@field::it
          firstFragment: #F22
          type: int
          getter: <testLibrary>::@extensionType::I2::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
      constructors
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I2::@constructor::new
          firstFragment: #F24
          formalParameters
            #E5 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F25
              type: int
              field: <testLibrary>::@extensionType::I2::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I2::@getter::it
          firstFragment: #F23
          returnType: int
          variable: <testLibrary>::@extensionType::I2::@field::it
''');
  }

  test_extensionType_interfaces_class() async {
    var library = await buildLibrary(r'''
class A {}

class B {}

class C implements A, B {}

extension type X(C it) implements A, B {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
        #F2 class B (nameOffset:18) (firstTokenOffset:12) (offset:18)
          element: <testLibrary>::@class::B
        #F3 class C (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@class::C
      extensionTypes
        #F4 extension type X (nameOffset:67) (firstTokenOffset:52) (offset:67)
          element: <testLibrary>::@extensionType::X
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
              element: <testLibrary>::@extensionType::X::@field::it
              inducedGetter: #F6
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
              element: <testLibrary>::@extensionType::X::@getter::it
              inducingVariable: #F5
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      interfaces
        A
        B
  extensionTypes
    isSimplyBounded extension type X
      reference: <testLibrary>::@extensionType::X
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::X::@field::it
      primaryConstructor: <testLibrary>::@extensionType::X::@constructor::new
      typeErasure: C
      interfaces
        A
        B
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::X::@field::it
          firstFragment: #F5
          type: C
          getter: <testLibrary>::@extensionType::X::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::X::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::X::@getter::it
          firstFragment: #F6
          returnType: C
          variable: <testLibrary>::@extensionType::X::@field::it
''');
  }

  test_extensionType_interfaces_cycle_2() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements B {}

extension type B(int it) implements A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
        #F4 extension type B (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::B::@field::it
              inducedGetter: #F6
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::B::@getter::it
              inducingVariable: #F5
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        Object
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      interfaces
        Object
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_extensionType_interfaces_cycle_self() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        Object
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_interfaces_extensionType() async {
    var library = await buildLibrary(r'''
extension type A(num it) {}

extension type B(int it) implements A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
        #F4 extension type B (nameOffset:44) (firstTokenOffset:29) (offset:44)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extensionType::B::@field::it
              inducedGetter: #F6
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extensionType::B::@getter::it
              inducingVariable: #F5
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: num
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: num
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      interfaces
        A
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_extensionType_interfaces_futureOr() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements num, FutureOr<int> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        num
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_interfaces_implicitObjectQuestion() async {
    var library = await buildLibrary(r'''
extension type X(int? it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type X (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::X
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::X::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::X::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type X
      reference: <testLibrary>::@extensionType::X
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::X::@field::it
      primaryConstructor: <testLibrary>::@extensionType::X::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::X::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::X::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::X::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::X::@getter::it
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::X::@field::it
''');
  }

  test_extensionType_interfaces_implicitObjectQuestion_fromTypeParameter() async {
    var library = await buildLibrary(r'''
extension type A<T>(T it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: T
      fields
        hasEnclosingTypeParameterReference isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: T
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: T
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_interfaces_void() async {
    var library = await buildLibrary(r'''
typedef A = void;

extension type X(int it) implements A, num {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type X (nameOffset:34) (firstTokenOffset:19) (offset:34)
          element: <testLibrary>::@extensionType::X
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extensionType::X::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extensionType::X::@getter::it
              inducingVariable: #F2
      typeAliases
        #F4 A (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::A
  extensionTypes
    isSimplyBounded extension type X
      reference: <testLibrary>::@extensionType::X
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::X::@field::it
      primaryConstructor: <testLibrary>::@extensionType::X::@constructor::new
      typeErasure: int
      interfaces
        num
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::X::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::X::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::X::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::X::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::X::@field::it
  typeAliases
    isSimplyBounded A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F4
      aliasedType: void
''');
  }

  test_extensionType_lazy_all_constructors() async {
    var library = await buildLibrary(r'''
extension type E.foo(int _) {}
''');

    var constructors = library.getExtensionType('E')!.constructors;
    expect(constructors, hasLength(1));
  }

  test_extensionType_lazy_all_fields() async {
    var library = await buildLibrary(r'''
extension type E(int _) {
  static int foo = 42;
}
''');

    var fields = library.getExtensionType('E')!.fields;
    expect(fields, hasLength(2));
  }

  test_extensionType_lazy_all_getters() async {
    var library = await buildLibrary(r'''
extension type E(int _) {
  int get foo => 0;
}
''');

    var getters = library.getExtensionType('E')!.getters;
    expect(getters, hasLength(2));
  }

  test_extensionType_lazy_all_methods() async {
    var library = await buildLibrary(r'''
extension type E(int _) {
  void foo() {}
}
''');

    var methods = library.getExtensionType('E')!.methods;
    expect(methods, hasLength(1));
  }

  test_extensionType_lazy_all_setters() async {
    var library = await buildLibrary(r'''
extension type E(int _) {
  set foo(int _) {}
}
''');

    var setters = library.getExtensionType('E')!.setters;
    expect(setters, hasLength(1));
  }

  test_extensionType_lazy_byReference_constructor() async {
    var library = await buildLibrary(r'''
extension type E.foo(int _) {}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtensionType('E')!;
    var foo = getConstructorElementOfReference(E, 'foo');
    expect(foo.name, 'foo');
  }

  test_extensionType_lazy_byReference_field() async {
    var library = await buildLibrary(r'''
extension type E(int _) {
  static int bar = 42;
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtensionType('E')!;
    var bar = getFieldElementOfReference(E, 'bar');
    expect(bar.name, 'bar');
  }

  test_extensionType_lazy_byReference_getter() async {
    var library = await buildLibrary(r'''
extension type E(int _) {
  int get foo => 0;
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtensionType('E')!;
    var foo = getGetterElementOfReference(E, 'foo');
    expect(foo.name, 'foo');
  }

  test_extensionType_lazy_byReference_method() async {
    var library = await buildLibrary(r'''
extension type E(int _) {
  void foo() {}
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtensionType('E')!;
    var foo = getMethodElementOfReference(E, 'foo');
    expect(foo.name, 'foo');
  }

  test_extensionType_lazy_byReference_setter() async {
    var library = await buildLibrary(r'''
extension type E(int _) {
  set foo(int _) {}
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtensionType('E')!;
    var foo = getSetterElementOfReference(E, 'foo');
    expect(foo.name, 'foo');
  }

  test_extensionType_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 0;
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@foo
extension type A(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      extensionTypes
        #F1 extension type A (nameOffset:38) (firstTokenOffset:18) (offset:38)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:38) (offset:38)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 38
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:44) (firstTokenOffset:40) (offset:44)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_missingName() async {
    var library = await buildLibrary(r'''
extension type (int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type <null-name> (nameOffset:<null>) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@extensionType::#0
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@extensionType::#0::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@extensionType::#0::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type <null-name>
      reference: <testLibrary>::@extensionType::#0
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::#0::@field::it
      primaryConstructor: <testLibrary>::@extensionType::#0::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::#0::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::#0::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::#0::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::#0::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::#0::@field::it
''');
  }

  test_extensionType_notSimplyBounded_self() async {
    var library = await buildLibrary(r'''
extension type A<T extends A>(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: A<dynamic>
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
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_typeErasure_hasExtension_cycle_2_direct() async {
    var library = await buildLibrary(r'''
extension type A(B it) {}

extension type B(A it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:19) (firstTokenOffset:17) (offset:19)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
        #F6 extension type B (nameOffset:42) (firstTokenOffset:27) (offset:42)
          element: <testLibrary>::@extensionType::B
          fields
            #F7 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@extensionType::B::@field::it
              inducedGetter: #F8
          constructors
            #F9 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@extensionType::B::@constructor::new
              typeName: B
              typeNameOffset: 42
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:46) (firstTokenOffset:44) (offset:46)
                  element: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
          getters
            #F8 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@extensionType::B::@getter::it
              inducingVariable: #F7
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: InvalidType
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F6
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F7
          type: InvalidType
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::B::@constructor::new
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F10
              type: InvalidType
              field: <testLibrary>::@extensionType::B::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F8
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_extensionType_typeErasure_hasExtension_cycle_2_typeArgument() async {
    var library = await buildLibrary(r'''
extension type A(B it) {}

extension type B(List<B> it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:19) (firstTokenOffset:17) (offset:19)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
        #F6 extension type B (nameOffset:42) (firstTokenOffset:27) (offset:42)
          element: <testLibrary>::@extensionType::B
          fields
            #F7 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@extensionType::B::@field::it
              inducedGetter: #F8
          constructors
            #F9 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@extensionType::B::@constructor::new
              typeName: B
              typeNameOffset: 42
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:52) (firstTokenOffset:44) (offset:52)
                  element: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
          getters
            #F8 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@extensionType::B::@getter::it
              inducingVariable: #F7
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: B
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: B
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: B
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F6
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F7
          type: InvalidType
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::B::@constructor::new
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F10
              type: InvalidType
              field: <testLibrary>::@extensionType::B::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F8
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_extensionType_typeErasure_hasExtension_cycle_self() async {
    var library = await buildLibrary(r'''
extension type A(A it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          constructors
            #F4 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:19) (firstTokenOffset:17) (offset:19)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F5
              type: InvalidType
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_typeErasure_hasExtension_functionType() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

extension type B(A Function(A a) it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
        #F4 extension type B (nameOffset:44) (firstTokenOffset:29) (offset:44)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extensionType::B::@field::it
              inducedGetter: #F6
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extensionType::B::@getter::it
              inducingVariable: #F5
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int Function(int)
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: A Function(A)
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F6
          returnType: A Function(A)
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_extensionType_typeErasure_hasExtension_interfaceType() async {
    var library = await buildLibrary(r'''
extension type A<T>(T it) {}

extension type B(A<double> it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
        #F5 extension type B (nameOffset:45) (firstTokenOffset:30) (offset:45)
          element: <testLibrary>::@extensionType::B
          fields
            #F6 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@extensionType::B::@field::it
              inducedGetter: #F7
          getters
            #F7 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@extensionType::B::@getter::it
              inducingVariable: #F6
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: T
      fields
        hasEnclosingTypeParameterReference isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: T
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: T
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F5
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: double
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F6
          type: A<double>
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F7
          returnType: A<double>
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_extensionType_typeErasure_hasExtension_interfaceType_typeArgument() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

extension type B(List<A> it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
        #F4 extension type B (nameOffset:44) (firstTokenOffset:29) (offset:44)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extensionType::B::@field::it
              inducedGetter: #F6
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extensionType::B::@getter::it
              inducingVariable: #F5
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    isSimplyBounded extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: List<int>
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: List<A>
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_extensionType_typeErasure_notExtension() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_typeParameters() async {
    var library = await buildLibrary(r'''
extension type A<T extends num, U>(Map<T, U> it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
            #F3 U (nameOffset:32) (firstTokenOffset:32) (offset:32)
              element: #E1 U
          fields
            #F4 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:45) (firstTokenOffset:35) (offset:45)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F4
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: num
        #E1 U
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Map<T, U>
      fields
        hasEnclosingTypeParameterReference isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F4
          type: Map<T, U>
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E2 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: Map<T, U>
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: Map<T, U>
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_typeParameters_augmentation_chain_bounds_int_string() async {
    var library = await buildLibrary(r'''
extension type A<T extends int>(int it) {}
augment extension type A<T extends String>(int it) {}
''');

    configuration.withDefaultType = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F6
              nextFragment: #F7
          constructors
            #F8 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:36) (firstTokenOffset:32) (offset:36)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F10
              nextFragment: #F11
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              nextFragment: #F12
        #F2 isAugmentation extension type A (nameOffset:66) (firstTokenOffset:43) (offset:66)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:68) (firstTokenOffset:68) (offset:68)
              element: #E0 T
              previousFragment: #F3
          fields
            #F7 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F12
              previousFragment: #F5
          constructors
            #F11 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:66) (offset:66)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 66
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:90) (firstTokenOffset:86) (offset:90)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F8
          getters
            #F12 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              previousFragment: #F6
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
          bound: int
          defaultType: int
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F9
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_typeParameters_augmentation_chain_count_111() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {}
augment extension type A<T>(int it) {}
augment extension type A<T>(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F6
              nextFragment: #F7
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              nextFragment: #F8
        #F2 isAugmentation extension type A (nameOffset:54) (firstTokenOffset:31) (offset:54)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F9
          typeParameters
            #F4 T (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F10
          fields
            #F7 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F8
              previousFragment: #F5
              nextFragment: #F11
          getters
            #F8 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              previousFragment: #F6
              nextFragment: #F12
        #F9 isAugmentation extension type A (nameOffset:93) (firstTokenOffset:70) (offset:93)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          typeParameters
            #F10 T (nameOffset:95) (firstTokenOffset:95) (offset:95)
              element: #E0 T
              previousFragment: #F4
          fields
            #F11 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:93)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F12
              previousFragment: #F7
          getters
            #F12 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:93)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F11
              previousFragment: #F8
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_typeParameters_augmentation_chain_count_112() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {}
augment extension type A<T>(int it) {}
augment extension type A<T, U>(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
            #F5 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: #E1 U
              nextFragment: #F6
          fields
            #F7 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F8
              nextFragment: #F9
          getters
            #F8 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              nextFragment: #F10
        #F2 isAugmentation extension type A (nameOffset:54) (firstTokenOffset:31) (offset:54)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F11
          typeParameters
            #F4 T (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F12
            #F6 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F13
          fields
            #F9 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F7
              nextFragment: #F14
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F9
              previousFragment: #F8
              nextFragment: #F15
        #F11 isAugmentation extension type A (nameOffset:93) (firstTokenOffset:70) (offset:93)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          typeParameters
            #F12 T (nameOffset:95) (firstTokenOffset:95) (offset:95)
              element: #E0 T
              previousFragment: #F4
            #F13 U (nameOffset:98) (firstTokenOffset:98) (offset:98)
              element: #E1 U
              previousFragment: #F6
          fields
            #F14 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:93)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F15
              previousFragment: #F9
          getters
            #F15 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:93)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F14
              previousFragment: #F10
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_typeParameters_augmentation_chain_count_121() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {}
augment extension type A<T, U>(int it) {}
augment extension type A<T>(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
            #F5 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: #E1 U
              nextFragment: #F6
          fields
            #F7 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F8
              nextFragment: #F9
          getters
            #F8 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              nextFragment: #F10
        #F2 isAugmentation extension type A (nameOffset:54) (firstTokenOffset:31) (offset:54)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F11
          typeParameters
            #F4 T (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F12
            #F6 U (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F13
          fields
            #F9 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F7
              nextFragment: #F14
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F9
              previousFragment: #F8
              nextFragment: #F15
        #F11 isAugmentation extension type A (nameOffset:96) (firstTokenOffset:73) (offset:96)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          typeParameters
            #F12 T (nameOffset:98) (firstTokenOffset:98) (offset:98)
              element: #E0 T
              previousFragment: #F4
            #F13 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: #E1 U
              previousFragment: #F6
          fields
            #F14 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F15
              previousFragment: #F9
          getters
            #F15 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F14
              previousFragment: #F10
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_typeParameters_augmentation_chain_count_123() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {}
augment extension type A<T, U>(int it) {}
augment extension type A<T, U, V>(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
            #F5 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: #E1 U
              nextFragment: #F6
            #F7 isOriginOtherFragmentOfEnclosing V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: #E2 V
              nextFragment: #F8
          fields
            #F9 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              nextFragment: #F11
          getters
            #F10 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F9
              nextFragment: #F12
        #F2 isAugmentation extension type A (nameOffset:54) (firstTokenOffset:31) (offset:54)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F13
          typeParameters
            #F4 T (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F14
            #F6 U (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F15
            #F8 isOriginOtherFragmentOfEnclosing V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: #E2 V
              previousFragment: #F7
              nextFragment: #F16
          fields
            #F11 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F12
              previousFragment: #F9
              nextFragment: #F17
          getters
            #F12 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F11
              previousFragment: #F10
              nextFragment: #F18
        #F13 isAugmentation extension type A (nameOffset:96) (firstTokenOffset:73) (offset:96)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          typeParameters
            #F14 T (nameOffset:98) (firstTokenOffset:98) (offset:98)
              element: #E0 T
              previousFragment: #F4
            #F15 U (nameOffset:101) (firstTokenOffset:101) (offset:101)
              element: #E1 U
              previousFragment: #F6
            #F16 V (nameOffset:104) (firstTokenOffset:104) (offset:104)
              element: #E2 V
              previousFragment: #F8
          fields
            #F17 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F18
              previousFragment: #F11
          getters
            #F18 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F17
              previousFragment: #F12
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F9
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_typeParameters_augmentation_chain_count_211() async {
    var library = await buildLibrary(r'''
extension type A<T, U>(int it) {}
augment extension type A<T>(int it) {}
augment extension type A<T>(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
            #F5 U (nameOffset:20) (firstTokenOffset:20) (offset:20)
              element: #E1 U
              nextFragment: #F6
          fields
            #F7 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F8
              nextFragment: #F9
          getters
            #F8 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              nextFragment: #F10
        #F2 isAugmentation extension type A (nameOffset:57) (firstTokenOffset:34) (offset:57)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F11
          typeParameters
            #F4 T (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F12
            #F6 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F13
          fields
            #F9 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F7
              nextFragment: #F14
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F9
              previousFragment: #F8
              nextFragment: #F15
        #F11 isAugmentation extension type A (nameOffset:96) (firstTokenOffset:73) (offset:96)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          typeParameters
            #F12 T (nameOffset:98) (firstTokenOffset:98) (offset:98)
              element: #E0 T
              previousFragment: #F4
            #F13 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: #E1 U
              previousFragment: #F6
          fields
            #F14 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F15
              previousFragment: #F9
          getters
            #F15 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F14
              previousFragment: #F10
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
        #E1 U
          firstFragment: #F5
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_extensionType_typeParameters_augmentation_chain_count_212() async {
    var library = await buildLibrary(r'''
extension type A<T, U>(int it) {}
augment extension type A<T>(int it) {}
augment extension type A<T, U>(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
            #F5 U (nameOffset:20) (firstTokenOffset:20) (offset:20)
              element: #E1 U
              nextFragment: #F6
          fields
            #F7 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F8
              nextFragment: #F9
          getters
            #F8 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              nextFragment: #F10
        #F2 isAugmentation extension type A (nameOffset:57) (firstTokenOffset:34) (offset:57)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F11
          typeParameters
            #F4 T (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F12
            #F6 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F13
          fields
            #F9 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F7
              nextFragment: #F14
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F9
              previousFragment: #F8
              nextFragment: #F15
        #F11 isAugmentation extension type A (nameOffset:96) (firstTokenOffset:73) (offset:96)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          typeParameters
            #F12 T (nameOffset:98) (firstTokenOffset:98) (offset:98)
              element: #E0 T
              previousFragment: #F4
            #F13 U (nameOffset:101) (firstTokenOffset:101) (offset:101)
              element: #E1 U
              previousFragment: #F6
          fields
            #F14 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F15
              previousFragment: #F9
          getters
            #F15 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F14
              previousFragment: #F10
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
        #E1 U
          firstFragment: #F5
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_field_augmentation_add() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo1 = 0;
}

augment extension type A(int it) {
  static int foo2 = 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 hasInitializer isOriginDeclaration isStatic foo1 (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo1
              inducedGetter: #F7
              inducedSetter: #F8
          constructors
            #F9 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F11
              nextFragment: #F12
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F13
            #F7 isComplete isOriginVariable isStatic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo1
              inducingVariable: #F6
          setters
            #F8 isComplete isOriginVariable isStatic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo1
              inducingVariable: #F6
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo1::@formalParameter::value
        #F2 isAugmentation extension type A (nameOffset:76) (firstTokenOffset:53) (offset:76)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F13
              previousFragment: #F3
            #F15 hasInitializer isOriginDeclaration isStatic foo2 (nameOffset:101) (firstTokenOffset:101) (offset:101)
              element: <testLibrary>::@extensionType::A::@field::foo2
              inducedGetter: #F16
              inducedSetter: #F17
          constructors
            #F12 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:76) (offset:76)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 76
              formalParameters
                #F11 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:82) (firstTokenOffset:78) (offset:82)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F10
              previousFragment: #F9
          getters
            #F13 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
            #F16 isComplete isOriginVariable isStatic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@extensionType::A::@getter::foo2
              inducingVariable: #F15
          setters
            #F17 isComplete isOriginVariable isStatic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@extensionType::A::@setter::foo2
              inducingVariable: #F15
              formalParameters
                #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
                  element: <testLibrary>::@extensionType::A::@setter::foo2::@formalParameter::value
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        hasInitializer isOriginDeclaration isStatic foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo1
          setter: <testLibrary>::@extensionType::A::@setter::foo1
        hasInitializer isOriginDeclaration isStatic foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F15
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo2
          setter: <testLibrary>::@extensionType::A::@setter::foo2
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F10
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable isStatic foo1
          reference: <testLibrary>::@extensionType::A::@getter::foo1
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember isOriginVariable isStatic foo2
          reference: <testLibrary>::@extensionType::A::@getter::foo2
          firstFragment: #F16
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo2
      setters
        isExtensionTypeMember isOriginVariable isStatic foo1
          reference: <testLibrary>::@extensionType::A::@setter::foo1
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F14
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember isOriginVariable isStatic foo2
          reference: <testLibrary>::@extensionType::A::@setter::foo2
          firstFragment: #F17
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F18
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo2
''');
  }

  test_field_augmentation_chain() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static int foo = 1;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 hasInitializer isOriginDeclaration isStatic foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F7
              inducedSetter: #F8
              nextFragment: #F9
          constructors
            #F10 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F11 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F12
              nextFragment: #F13
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F14
            #F7 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F6
              nextFragment: #F15
          setters
            #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F6
              formalParameters
                #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  nextFragment: #F17
              nextFragment: #F18
        #F2 isAugmentation extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F14
              previousFragment: #F3
            #F9 hasInitializer isAugmentation isOriginDeclaration isStatic foo (nameOffset:108) (firstTokenOffset:108) (offset:108)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F15
              inducedSetter: #F18
              previousFragment: #F6
          constructors
            #F13 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F12 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F11
              previousFragment: #F10
          getters
            #F14 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
            #F15 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F9
              previousFragment: #F7
          setters
            #F18 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F9
              formalParameters
                #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  previousFragment: #F16
              previousFragment: #F8
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        hasInitializer isOriginDeclaration isStatic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F10
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F11
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F16
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_field_augmentation_chain_afterGetter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static int get foo => 1;
}

augment extension type A(int it) {
  augment static int foo = 2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 hasInitializer isOriginDeclaration isStatic foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F7
              inducedSetter: #F8
              nextFragment: #F9
          constructors
            #F10 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F11 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F12
              nextFragment: #F13
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F14
            #F7 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F6
              nextFragment: #F15
          setters
            #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F6
              formalParameters
                #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  nextFragment: #F17
              nextFragment: #F18
        #F2 isAugmentation extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F19
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F14
              previousFragment: #F3
              nextFragment: #F20
          constructors
            #F13 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F12 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F11
                  nextFragment: #F21
              nextFragment: #F22
              previousFragment: #F10
          getters
            #F14 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
              nextFragment: #F23
            #F15 isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:112) (firstTokenOffset:89) (offset:112)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F7
              nextFragment: #F24
        #F19 isAugmentation extension type A (nameOffset:148) (firstTokenOffset:125) (offset:148)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F20 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F23
              previousFragment: #F5
            #F9 hasInitializer isAugmentation isOriginDeclaration isStatic foo (nameOffset:181) (firstTokenOffset:181) (offset:181)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F24
              inducedSetter: #F18
              previousFragment: #F6
          constructors
            #F22 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:148) (offset:148)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 148
              formalParameters
                #F21 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:154) (firstTokenOffset:150) (offset:154)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F12
              previousFragment: #F13
          getters
            #F23 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F20
              previousFragment: #F14
            #F24 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:181)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F9
              previousFragment: #F15
          setters
            #F18 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:181)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F9
              formalParameters
                #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:181)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  previousFragment: #F16
              previousFragment: #F8
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        hasInitializer isOriginDeclaration isStatic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F10
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F11
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F16
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_field_augmentation_chain_afterSetter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static set foo(int _) {}
}

augment extension type A(int it) {
  augment static int foo = 2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 hasInitializer isOriginDeclaration isStatic foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F7
              inducedSetter: #F8
              nextFragment: #F9
          constructors
            #F10 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F11 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F12
              nextFragment: #F13
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F14
            #F7 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F6
              nextFragment: #F15
          setters
            #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F6
              formalParameters
                #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  nextFragment: #F17
              nextFragment: #F18
        #F2 isAugmentation extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F19
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F14
              previousFragment: #F3
              nextFragment: #F20
          constructors
            #F13 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F12 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F11
                  nextFragment: #F21
              nextFragment: #F22
              previousFragment: #F10
          getters
            #F14 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
              nextFragment: #F23
          setters
            #F18 hasImplicitReturnType isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:108) (firstTokenOffset:89) (offset:108)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F17 requiredPositional isOriginDeclaration _ (nameOffset:116) (firstTokenOffset:112) (offset:116)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  previousFragment: #F16
                  nextFragment: #F24
              previousFragment: #F8
              nextFragment: #F25
        #F19 isAugmentation extension type A (nameOffset:148) (firstTokenOffset:125) (offset:148)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F20 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F23
              previousFragment: #F5
            #F9 hasInitializer isAugmentation isOriginDeclaration isStatic foo (nameOffset:181) (firstTokenOffset:181) (offset:181)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F15
              inducedSetter: #F25
              previousFragment: #F6
          constructors
            #F22 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:148) (offset:148)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 148
              formalParameters
                #F21 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:154) (firstTokenOffset:150) (offset:154)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F12
              previousFragment: #F13
          getters
            #F23 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F20
              previousFragment: #F14
            #F15 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:181)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F9
              previousFragment: #F7
          setters
            #F25 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:181)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F9
              formalParameters
                #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:181)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  previousFragment: #F17
              previousFragment: #F18
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        hasInitializer isOriginDeclaration isStatic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F10
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F11
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F16
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_field_augmentation_chain_differentType() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static double foo = 1.2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 hasInitializer isOriginDeclaration isStatic foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F7
              inducedSetter: #F8
              nextFragment: #F9
          constructors
            #F10 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F11 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F12
              nextFragment: #F13
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F14
            #F7 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F6
              nextFragment: #F15
          setters
            #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F6
              formalParameters
                #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  nextFragment: #F17
              nextFragment: #F18
        #F2 isAugmentation extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F14
              previousFragment: #F3
            #F9 hasInitializer isAugmentation isOriginDeclaration isStatic foo (nameOffset:111) (firstTokenOffset:111) (offset:111)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F15
              inducedSetter: #F18
              previousFragment: #F6
          constructors
            #F13 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F12 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F11
              previousFragment: #F10
          getters
            #F14 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
            #F15 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:111)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F9
              previousFragment: #F7
          setters
            #F18 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:111)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F9
              formalParameters
                #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:111)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  previousFragment: #F16
              previousFragment: #F8
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        hasInitializer isOriginDeclaration isStatic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F10
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F11
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F16
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_field_augmentation_chain_fromGetter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int get foo => 0;
}

augment extension type A(int it) {
  augment static int foo = 1;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F7
          constructors
            #F8 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F10
              nextFragment: #F11
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F12
            #F13 isComplete isOriginDeclaration isStatic foo (nameOffset:44) (firstTokenOffset:29) (offset:44)
              element: <testLibrary>::@extensionType::A::@getter::foo
              nextFragment: #F14
        #F2 isAugmentation extension type A (nameOffset:80) (firstTokenOffset:57) (offset:80)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F12
              previousFragment: #F3
            #F7 hasInitializer isAugmentation isOriginDeclaration isStatic foo (nameOffset:113) (firstTokenOffset:113) (offset:113)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F14
              inducedSetter: #F15
              previousFragment: #F6
          constructors
            #F11 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:80) (offset:80)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 80
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:86) (firstTokenOffset:82) (offset:86)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F8
          getters
            #F12 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
            #F14 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:113)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F7
              previousFragment: #F13
          setters
            #F15 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:113)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F7
              formalParameters
                #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:113)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        hasInitializer isOriginGetterSetter isStatic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F9
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F13
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F15
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F16
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_field_augmentation_chain_twoDeclarations() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static int foo = 1;
}

augment extension type A(int it) {
  augment static int foo = 2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 hasInitializer isOriginDeclaration isStatic foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F7
              inducedSetter: #F8
              nextFragment: #F9
          constructors
            #F10 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F11 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F12
              nextFragment: #F13
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F14
            #F7 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F6
              nextFragment: #F15
          setters
            #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F6
              formalParameters
                #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  nextFragment: #F17
              nextFragment: #F18
        #F2 isAugmentation extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F19
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F14
              previousFragment: #F3
              nextFragment: #F20
            #F9 hasInitializer isAugmentation isOriginDeclaration isStatic foo (nameOffset:108) (firstTokenOffset:108) (offset:108)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F15
              inducedSetter: #F18
              previousFragment: #F6
              nextFragment: #F21
          constructors
            #F13 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F12 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F11
                  nextFragment: #F22
              nextFragment: #F23
              previousFragment: #F10
          getters
            #F14 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
              nextFragment: #F24
            #F15 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F9
              previousFragment: #F7
              nextFragment: #F25
          setters
            #F18 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F9
              formalParameters
                #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  previousFragment: #F16
                  nextFragment: #F26
              previousFragment: #F8
              nextFragment: #F27
        #F19 isAugmentation extension type A (nameOffset:143) (firstTokenOffset:120) (offset:143)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F20 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:143)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F24
              previousFragment: #F5
            #F21 hasInitializer isAugmentation isOriginDeclaration isStatic foo (nameOffset:176) (firstTokenOffset:176) (offset:176)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F25
              inducedSetter: #F27
              previousFragment: #F9
          constructors
            #F23 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:143) (offset:143)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 143
              formalParameters
                #F22 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:149) (firstTokenOffset:145) (offset:149)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F12
              previousFragment: #F13
          getters
            #F24 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:143)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F20
              previousFragment: #F14
            #F25 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:176)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F21
              previousFragment: #F15
          setters
            #F27 isAugmentation isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:176)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F21
              formalParameters
                #F26 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:176)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  previousFragment: #F17
              previousFragment: #F18
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        hasInitializer isOriginDeclaration isStatic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F10
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F11
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F16
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_field_isPromotable_representationField_private() async {
    var library = await buildLibrary(r'''
extension type A(int? _it) {}

class B {
  int _it = 0;
}

class C {
  int get _it => 0;
}
''');

    configuration
      ..forPromotableFields(extensionTypeNames: {'A'})
      ..withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F0
      representation: <testLibrary>::@extensionType::A::@field::_it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        isFinal isOriginDeclaringFormalParameter isPromotable _it
          reference: <testLibrary>::@extensionType::A::@field::_it
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::_it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_it
  fieldNameNonPromotabilityInfo
    _it
      conflictingFields
        <testLibrary>::@class::B::@field::_it
      conflictingGetters
        <testLibrary>::@class::C::@getter::_it
''');
  }

  test_field_static_const_typed() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static const int foo = 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
            #F4 hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: <testLibrary>::@extensionType::A::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @52
                  staticType: int
              inducedGetter: #F5
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F4
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        hasInitializer isConst isOriginDeclaration isStatic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@extensionType::A::@getter::foo
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_field_static_const_untyped() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static const foo = 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
            #F4 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@extensionType::A::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @48
                  staticType: int
              inducedGetter: #F5
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F4
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@extensionType::A::@getter::foo
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_field_untyped() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  final foo = 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
            #F4 hasImplicitType hasInitializer isFinal isOriginDeclaration foo (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F5
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
            #F5 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F4
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        hasImplicitType hasInitializer isFinal isOriginDeclaration isTypeInferredFromInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_getter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  int get foo => 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
            #F4 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
            #F5 isComplete isOriginDeclaration foo (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::foo
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        isOriginGetterSetter foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_getter_augmentation_add() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  int get foo1 => 0;
}

augment extension type A(int it) {
  int get foo2 => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
          constructors
            #F7 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F11
            #F12 isComplete isOriginDeclaration foo1 (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::foo1
        #F2 isAugmentation extension type A (nameOffset:74) (firstTokenOffset:51) (offset:74)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F11
              previousFragment: #F3
            #F13 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F10 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:74) (offset:74)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 74
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:80) (firstTokenOffset:76) (offset:80)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F7
          getters
            #F11 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
            #F14 isComplete isOriginDeclaration foo2 (nameOffset:96) (firstTokenOffset:88) (offset:96)
              element: <testLibrary>::@extensionType::A::@getter::foo2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F13
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo2
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@getter::foo1
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember isOriginDeclaration foo2
          reference: <testLibrary>::@extensionType::A::@getter::foo2
          firstFragment: #F14
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo2
''');
  }

  test_getter_augmentation_add_generic() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {
  T get foo1;
}

augment extension type A<T>(int it) {
  T get foo2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F6
              nextFragment: #F7
            #F8 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
          constructors
            #F9 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F11
              nextFragment: #F12
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              nextFragment: #F13
            #F14 isAbstract isOriginDeclaration foo1 (nameOffset:38) (firstTokenOffset:32) (offset:38)
              element: <testLibrary>::@extensionType::A::@getter::foo1
        #F2 isAugmentation extension type A (nameOffset:70) (firstTokenOffset:47) (offset:70)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:72) (firstTokenOffset:72) (offset:72)
              element: #E0 T
              previousFragment: #F3
          fields
            #F7 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F13
              previousFragment: #F5
            #F15 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F12 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:70) (offset:70)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 70
              formalParameters
                #F11 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:79) (firstTokenOffset:75) (offset:79)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F10
              previousFragment: #F9
          getters
            #F13 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              previousFragment: #F6
            #F16 isAbstract isOriginDeclaration foo2 (nameOffset:93) (firstTokenOffset:87) (offset:93)
              element: <testLibrary>::@extensionType::A::@getter::foo2
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        hasEnclosingTypeParameterReference isOriginGetterSetter foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F8
          type: T
          getter: <testLibrary>::@extensionType::A::@getter::foo1
        hasEnclosingTypeParameterReference isOriginGetterSetter foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F15
          type: T
          getter: <testLibrary>::@extensionType::A::@getter::foo2
      constructors
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F10
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@getter::foo1
          firstFragment: #F14
          returnType: T
          variable: <testLibrary>::@extensionType::A::@field::foo1
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration foo2
          reference: <testLibrary>::@extensionType::A::@getter::foo2
          firstFragment: #F16
          returnType: T
          variable: <testLibrary>::@extensionType::A::@field::foo2
''');
  }

  test_getter_augmentation_chain() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  int get foo1 => 0;
  int get foo2 => 0;
}

augment extension type A(int it) {
  augment int get foo1 => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
            #F7 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F8 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F10
              nextFragment: #F11
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F12
            #F13 isComplete isOriginDeclaration foo1 (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::foo1
              nextFragment: #F14
            #F15 isComplete isOriginDeclaration foo2 (nameOffset:58) (firstTokenOffset:50) (offset:58)
              element: <testLibrary>::@extensionType::A::@getter::foo2
        #F2 isAugmentation extension type A (nameOffset:95) (firstTokenOffset:72) (offset:95)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F12
              previousFragment: #F3
          constructors
            #F11 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:95) (offset:95)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 95
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:101) (firstTokenOffset:97) (offset:101)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F8
          getters
            #F12 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
            #F14 isAugmentation isComplete isOriginDeclaration foo1 (nameOffset:125) (firstTokenOffset:109) (offset:125)
              element: <testLibrary>::@extensionType::A::@getter::foo1
              previousFragment: #F13
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo2
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F9
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@getter::foo1
          firstFragment: #F13
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember isOriginDeclaration foo2
          reference: <testLibrary>::@extensionType::A::@getter::foo2
          firstFragment: #F15
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo2
''');
  }

  test_getter_augmentation_chain_fromField() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static int get foo => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 hasInitializer isOriginDeclaration isStatic foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F7
              inducedSetter: #F8
          constructors
            #F9 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F11
              nextFragment: #F12
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F13
            #F7 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F6
              nextFragment: #F14
          setters
            #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F6
              formalParameters
                #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 isAugmentation extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F13
              previousFragment: #F3
          constructors
            #F12 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F11 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F10
              previousFragment: #F9
          getters
            #F13 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
            #F14 isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:112) (firstTokenOffset:89) (offset:112)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F7
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        hasInitializer isOriginDeclaration isStatic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F10
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F15
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_getter_augmentation_chain_fromField_twoDeclarations() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static int get foo => 0;
}

augment extension type A(int it) {
  augment static int get foo => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 hasInitializer isOriginDeclaration isStatic foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F7
              inducedSetter: #F8
          constructors
            #F9 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F11
              nextFragment: #F12
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F13
            #F7 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F6
              nextFragment: #F14
          setters
            #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F6
              formalParameters
                #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 isAugmentation extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F16
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F13
              previousFragment: #F3
              nextFragment: #F17
          constructors
            #F12 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F11 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F10
                  nextFragment: #F18
              nextFragment: #F19
              previousFragment: #F9
          getters
            #F13 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
              nextFragment: #F20
            #F14 isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:112) (firstTokenOffset:89) (offset:112)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F7
              nextFragment: #F21
        #F16 isAugmentation extension type A (nameOffset:148) (firstTokenOffset:125) (offset:148)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F17 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F20
              previousFragment: #F5
          constructors
            #F19 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:148) (offset:148)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 148
              formalParameters
                #F18 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:154) (firstTokenOffset:150) (offset:154)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F11
              previousFragment: #F12
          getters
            #F20 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F17
              previousFragment: #F13
            #F21 isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:185) (firstTokenOffset:162) (offset:185)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F14
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        hasInitializer isOriginDeclaration isStatic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F10
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F15
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_getter_augmentation_chain_twoDeclarations() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  int get foo => 0;
}

augment extension type A(int it) {
  augment int get foo => 0;
}

augment extension type A(int it) {
  augment int get foo => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo
          constructors
            #F7 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F11
            #F12 isComplete isOriginDeclaration foo (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::foo
              nextFragment: #F13
        #F2 isAugmentation extension type A (nameOffset:73) (firstTokenOffset:50) (offset:73)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F14
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F11
              previousFragment: #F3
              nextFragment: #F15
          constructors
            #F10 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:73) (offset:73)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 73
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:79) (firstTokenOffset:75) (offset:79)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
                  nextFragment: #F16
              nextFragment: #F17
              previousFragment: #F7
          getters
            #F11 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
              nextFragment: #F18
            #F13 isAugmentation isComplete isOriginDeclaration foo (nameOffset:103) (firstTokenOffset:87) (offset:103)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F12
              nextFragment: #F19
        #F14 isAugmentation extension type A (nameOffset:139) (firstTokenOffset:116) (offset:139)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F15 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:139)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F18
              previousFragment: #F5
          constructors
            #F17 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:139) (offset:139)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 139
              formalParameters
                #F16 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:145) (firstTokenOffset:141) (offset:145)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F10
          getters
            #F18 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:139)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F15
              previousFragment: #F11
            #F19 isAugmentation isComplete isOriginDeclaration foo (nameOffset:169) (firstTokenOffset:153) (offset:169)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F13
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        isOriginGetterSetter foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_method() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo(int a) {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
          methods
            #F4 isComplete isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              formalParameters
                #F5 requiredPositional isOriginDeclaration a (nameOffset:42) (firstTokenOffset:38) (offset:42)
                  element: <testLibrary>::@extensionType::A::@method::foo::@formalParameter::a
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F5
              type: int
          returnType: void
''');
  }

  test_method_augmentation_add() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}

augment extension type A(int it) {
  void bar() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F10
          methods
            #F11 isComplete isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
        #F2 isAugmentation extension type A (nameOffset:69) (firstTokenOffset:46) (offset:69)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F3
          constructors
            #F9 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:69) (offset:69)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 69
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:75) (firstTokenOffset:71) (offset:75)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F6
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
          methods
            #F12 isComplete isOriginDeclaration bar (nameOffset:88) (firstTokenOffset:83) (offset:88)
              element: <testLibrary>::@extensionType::A::@method::bar
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F11
          returnType: void
        isExtensionTypeMember isOriginDeclaration bar
          reference: <testLibrary>::@extensionType::A::@method::bar
          firstFragment: #F12
          returnType: void
''');
  }

  test_method_augmentation_add_generic() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {
  T foo() => throw 0;
}

augment extension type A<T>(int it) {
  T bar() => throw 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F6
              nextFragment: #F7
          constructors
            #F8 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F10
              nextFragment: #F11
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              nextFragment: #F12
          methods
            #F13 isComplete isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:32) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
        #F2 isAugmentation extension type A (nameOffset:78) (firstTokenOffset:55) (offset:78)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:80) (firstTokenOffset:80) (offset:80)
              element: #E0 T
              previousFragment: #F3
          fields
            #F7 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F12
              previousFragment: #F5
          constructors
            #F11 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:78) (offset:78)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 78
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:87) (firstTokenOffset:83) (offset:87)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F8
          getters
            #F12 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              previousFragment: #F6
          methods
            #F14 isComplete isOriginDeclaration bar (nameOffset:97) (firstTokenOffset:95) (offset:97)
              element: <testLibrary>::@extensionType::A::@method::bar
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F9
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F13
          returnType: T
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration bar
          reference: <testLibrary>::@extensionType::A::@method::bar
          firstFragment: #F14
          returnType: T
''');
  }

  test_method_augmentation_chain() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo1() {}
  void foo2() {}
}

augment extension type A(int it) {
  augment void foo1() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F10
          methods
            #F11 isComplete isOriginDeclaration foo1 (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo1
              nextFragment: #F12
            #F13 isComplete isOriginDeclaration foo2 (nameOffset:51) (firstTokenOffset:46) (offset:51)
              element: <testLibrary>::@extensionType::A::@method::foo2
        #F2 isAugmentation extension type A (nameOffset:87) (firstTokenOffset:64) (offset:87)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:87)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F3
          constructors
            #F9 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:87) (offset:87)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 87
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:93) (firstTokenOffset:89) (offset:93)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F6
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:87)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
          methods
            #F12 isAugmentation isComplete isOriginDeclaration foo1 (nameOffset:114) (firstTokenOffset:101) (offset:114)
              element: <testLibrary>::@extensionType::A::@method::foo1
              previousFragment: #F11
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@method::foo1
          firstFragment: #F11
          returnType: void
        isExtensionTypeMember isOriginDeclaration foo2
          reference: <testLibrary>::@extensionType::A::@method::foo2
          firstFragment: #F13
          returnType: void
''');
  }

  test_method_augmentation_chain_enclosingTypeParameters_countMismatch() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
  void bar() {}
}

augment extension type A<T>(int it) {
  augment void foo() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 isOriginOtherFragmentOfEnclosing T (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F6
              nextFragment: #F7
          constructors
            #F8 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F10
              nextFragment: #F11
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              nextFragment: #F12
          methods
            #F13 isComplete isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              nextFragment: #F14
            #F15 isComplete isOriginDeclaration bar (nameOffset:50) (firstTokenOffset:45) (offset:50)
              element: <testLibrary>::@extensionType::A::@method::bar
        #F2 isAugmentation extension type A (nameOffset:85) (firstTokenOffset:62) (offset:85)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:87) (firstTokenOffset:87) (offset:87)
              element: #E0 T
              previousFragment: #F3
          fields
            #F7 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:85)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F12
              previousFragment: #F5
          constructors
            #F11 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:85) (offset:85)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 85
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:94) (firstTokenOffset:90) (offset:94)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F8
          getters
            #F12 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:85)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              previousFragment: #F6
          methods
            #F14 isAugmentation isComplete isOriginDeclaration foo (nameOffset:115) (firstTokenOffset:102) (offset:115)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F13
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F9
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F13
          returnType: void
        isExtensionTypeMember isOriginDeclaration bar
          reference: <testLibrary>::@extensionType::A::@method::bar
          firstFragment: #F15
          returnType: void
''');
  }

  test_method_augmentation_chain_generic() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {
  T foo() => throw 0;
}

augment extension type A<T>(int it) {
  augment T foo() => throw 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F6
              nextFragment: #F7
          constructors
            #F8 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F10
              nextFragment: #F11
          getters
            #F6 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              nextFragment: #F12
          methods
            #F13 isComplete isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:32) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              nextFragment: #F14
        #F2 isAugmentation extension type A (nameOffset:78) (firstTokenOffset:55) (offset:78)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:80) (firstTokenOffset:80) (offset:80)
              element: #E0 T
              previousFragment: #F3
          fields
            #F7 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F12
              previousFragment: #F5
          constructors
            #F11 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:78) (offset:78)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 78
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:87) (firstTokenOffset:83) (offset:87)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F8
          getters
            #F12 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F7
              previousFragment: #F6
          methods
            #F14 isAugmentation isComplete isOriginDeclaration foo (nameOffset:105) (firstTokenOffset:95) (offset:105)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F13
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F9
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        hasEnclosingTypeParameterReference isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F13
          returnType: T
''');
  }

  test_method_augmentation_chain_twoDeclarations() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}

augment extension type A(int it) {
  augment void foo() {}
}

augment extension type A(int it) {
  augment void foo() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F10
          methods
            #F11 isComplete isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              nextFragment: #F12
        #F2 isAugmentation extension type A (nameOffset:69) (firstTokenOffset:46) (offset:69)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F13
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F3
              nextFragment: #F14
          constructors
            #F9 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:69) (offset:69)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 69
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:75) (firstTokenOffset:71) (offset:75)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
                  nextFragment: #F15
              nextFragment: #F16
              previousFragment: #F6
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
              nextFragment: #F17
          methods
            #F12 isAugmentation isComplete isOriginDeclaration foo (nameOffset:96) (firstTokenOffset:83) (offset:96)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F11
              nextFragment: #F18
        #F13 isAugmentation extension type A (nameOffset:131) (firstTokenOffset:108) (offset:131)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F14 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:131)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F17
              previousFragment: #F5
          constructors
            #F16 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:131) (offset:131)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 131
              formalParameters
                #F15 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:137) (firstTokenOffset:133) (offset:137)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F9
          getters
            #F17 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:131)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F14
              previousFragment: #F10
          methods
            #F18 isAugmentation isComplete isOriginDeclaration foo (nameOffset:158) (firstTokenOffset:145) (offset:158)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F12
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F11
          returnType: void
''');
  }

  test_method_augmentation_chain_typeParameters_count_112() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo<T>() {}
}
augment extension type A(int it) {
  augment void foo<T>() {}
}
augment extension type A(int it) {
  augment void foo<T, U>() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F10
          methods
            #F11 isComplete isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              nextFragment: #F12
              typeParameters
                #F13 T (nameOffset:38) (firstTokenOffset:38) (offset:38)
                  element: #E0 T
                  nextFragment: #F14
                #F15 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: #E1 U
                  nextFragment: #F16
        #F2 isAugmentation extension type A (nameOffset:71) (firstTokenOffset:48) (offset:71)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F17
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F3
              nextFragment: #F18
          constructors
            #F9 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:71) (offset:71)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 71
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:77) (firstTokenOffset:73) (offset:77)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
                  nextFragment: #F19
              nextFragment: #F20
              previousFragment: #F6
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
              nextFragment: #F21
          methods
            #F12 isAugmentation isComplete isOriginDeclaration foo (nameOffset:98) (firstTokenOffset:85) (offset:98)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F11
              nextFragment: #F22
              typeParameters
                #F14 T (nameOffset:102) (firstTokenOffset:102) (offset:102)
                  element: #E0 T
                  previousFragment: #F13
                  nextFragment: #F23
                #F16 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
                  element: #E1 U
                  previousFragment: #F15
                  nextFragment: #F24
        #F17 isAugmentation extension type A (nameOffset:135) (firstTokenOffset:112) (offset:135)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F18 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:135)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F21
              previousFragment: #F5
          constructors
            #F20 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:135) (offset:135)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 135
              formalParameters
                #F19 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:141) (firstTokenOffset:137) (offset:141)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F9
          getters
            #F21 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:135)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F18
              previousFragment: #F10
          methods
            #F22 isAugmentation isComplete isOriginDeclaration foo (nameOffset:162) (firstTokenOffset:149) (offset:162)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F12
              typeParameters
                #F23 T (nameOffset:166) (firstTokenOffset:166) (offset:166)
                  element: #E0 T
                  previousFragment: #F14
                #F24 U (nameOffset:169) (firstTokenOffset:169) (offset:169)
                  element: #E1 U
                  previousFragment: #F16
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
          firstFragment: #F6
          formalParameters
            #E2 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F11
          typeParameters
            #E0 T
              firstFragment: #F13
          returnType: void
''');
  }

  test_method_augmentation_chain_typeParameters_count_123() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo<T>() {}
}
augment extension type A(int it) {
  augment void foo<T, U>() {}
}
augment extension type A(int it) {
  augment void foo<T, U, V>() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F10
          methods
            #F11 isComplete isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              nextFragment: #F12
              typeParameters
                #F13 T (nameOffset:38) (firstTokenOffset:38) (offset:38)
                  element: #E0 T
                  nextFragment: #F14
                #F15 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: #E1 U
                  nextFragment: #F16
                #F17 isOriginOtherFragmentOfEnclosing V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: #E2 V
                  nextFragment: #F18
        #F2 isAugmentation extension type A (nameOffset:71) (firstTokenOffset:48) (offset:71)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F19
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F3
              nextFragment: #F20
          constructors
            #F9 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:71) (offset:71)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 71
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:77) (firstTokenOffset:73) (offset:77)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
                  nextFragment: #F21
              nextFragment: #F22
              previousFragment: #F6
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
              nextFragment: #F23
          methods
            #F12 isAugmentation isComplete isOriginDeclaration foo (nameOffset:98) (firstTokenOffset:85) (offset:98)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F11
              nextFragment: #F24
              typeParameters
                #F14 T (nameOffset:102) (firstTokenOffset:102) (offset:102)
                  element: #E0 T
                  previousFragment: #F13
                  nextFragment: #F25
                #F16 U (nameOffset:105) (firstTokenOffset:105) (offset:105)
                  element: #E1 U
                  previousFragment: #F15
                  nextFragment: #F26
                #F18 isOriginOtherFragmentOfEnclosing V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
                  element: #E2 V
                  previousFragment: #F17
                  nextFragment: #F27
        #F19 isAugmentation extension type A (nameOffset:138) (firstTokenOffset:115) (offset:138)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F20 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:138)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F23
              previousFragment: #F5
          constructors
            #F22 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:138) (offset:138)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 138
              formalParameters
                #F21 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:144) (firstTokenOffset:140) (offset:144)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F9
          getters
            #F23 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:138)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F20
              previousFragment: #F10
          methods
            #F24 isAugmentation isComplete isOriginDeclaration foo (nameOffset:165) (firstTokenOffset:152) (offset:165)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F12
              typeParameters
                #F25 T (nameOffset:169) (firstTokenOffset:169) (offset:169)
                  element: #E0 T
                  previousFragment: #F14
                #F26 U (nameOffset:172) (firstTokenOffset:172) (offset:172)
                  element: #E1 U
                  previousFragment: #F16
                #F27 V (nameOffset:175) (firstTokenOffset:175) (offset:175)
                  element: #E2 V
                  previousFragment: #F18
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
          firstFragment: #F6
          formalParameters
            #E3 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F11
          typeParameters
            #E0 T
              firstFragment: #F13
          returnType: void
''');
  }

  test_method_augmentation_chain_typeParameters_count_211() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo<T, U>() {}
}
augment extension type A(int it) {
  augment void foo<T>() {}
}
augment extension type A(int it) {
  augment void foo<T>() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
          constructors
            #F6 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F10
          methods
            #F11 isComplete isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              nextFragment: #F12
              typeParameters
                #F13 T (nameOffset:38) (firstTokenOffset:38) (offset:38)
                  element: #E0 T
                  nextFragment: #F14
                #F15 U (nameOffset:41) (firstTokenOffset:41) (offset:41)
                  element: #E1 U
                  nextFragment: #F16
        #F2 isAugmentation extension type A (nameOffset:74) (firstTokenOffset:51) (offset:74)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F17
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F10
              previousFragment: #F3
              nextFragment: #F18
          constructors
            #F9 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:74) (offset:74)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 74
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:80) (firstTokenOffset:76) (offset:80)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
                  nextFragment: #F19
              nextFragment: #F20
              previousFragment: #F6
          getters
            #F10 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
              nextFragment: #F21
          methods
            #F12 isAugmentation isComplete isOriginDeclaration foo (nameOffset:101) (firstTokenOffset:88) (offset:101)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F11
              nextFragment: #F22
              typeParameters
                #F14 T (nameOffset:105) (firstTokenOffset:105) (offset:105)
                  element: #E0 T
                  previousFragment: #F13
                  nextFragment: #F23
                #F16 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
                  element: #E1 U
                  previousFragment: #F15
                  nextFragment: #F24
        #F17 isAugmentation extension type A (nameOffset:138) (firstTokenOffset:115) (offset:138)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F18 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:138)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F21
              previousFragment: #F5
          constructors
            #F20 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:138) (offset:138)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 138
              formalParameters
                #F19 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:144) (firstTokenOffset:140) (offset:144)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F9
          getters
            #F21 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:138)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F18
              previousFragment: #F10
          methods
            #F22 isAugmentation isComplete isOriginDeclaration foo (nameOffset:165) (firstTokenOffset:152) (offset:165)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F12
              typeParameters
                #F23 T (nameOffset:169) (firstTokenOffset:169) (offset:169)
                  element: #E0 T
                  previousFragment: #F14
                #F24 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:165)
                  element: #E1 U
                  previousFragment: #F16
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
          firstFragment: #F6
          formalParameters
            #E2 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F11
          typeParameters
            #E0 T
              firstFragment: #F13
            #E1 U
              firstFragment: #F15
          returnType: void
''');
  }

  test_method_formalParameter_regular_optionalNamed_withDefault() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo({int a = 0}) {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
          methods
            #F4 isComplete isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              formalParameters
                #F5 optionalNamed isOriginDeclaration a (nameOffset:43) (firstTokenOffset:39) (offset:43)
                  element: <testLibrary>::@extensionType::A::@method::foo::@formalParameter::a
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @47
                      staticType: int
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed hasDefaultValue a
              firstFragment: #F5
              type: int
              constantInitializer
                fragment: #F5
                expression: expression_0
          returnType: void
''');
  }

  test_setter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  set foo(double _) {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F3
            #F4 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo
          getters
            #F3 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F2
          setters
            #F5 hasImplicitReturnType isComplete isOriginDeclaration foo (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F6 requiredPositional isOriginDeclaration _ (nameOffset:44) (firstTokenOffset:37) (offset:44)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::_
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        isOriginGetterSetter foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F4
          type: double
          setter: <testLibrary>::@extensionType::A::@setter::foo
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      setters
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F6
              type: double
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_setter_augmentation_add() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  set foo1(int _) {}
}

augment extension type A(int it) {
  set foo2(int _) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
          constructors
            #F7 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F11
          setters
            #F12 hasImplicitReturnType isComplete isOriginDeclaration foo1 (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@extensionType::A::@setter::foo1
              formalParameters
                #F13 requiredPositional isOriginDeclaration _ (nameOffset:42) (firstTokenOffset:38) (offset:42)
                  element: <testLibrary>::@extensionType::A::@setter::foo1::@formalParameter::_
        #F2 isAugmentation extension type A (nameOffset:74) (firstTokenOffset:51) (offset:74)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F11
              previousFragment: #F3
            #F14 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F10 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:74) (offset:74)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 74
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:80) (firstTokenOffset:76) (offset:80)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F7
          getters
            #F11 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
          setters
            #F15 hasImplicitReturnType isComplete isOriginDeclaration foo2 (nameOffset:92) (firstTokenOffset:88) (offset:92)
              element: <testLibrary>::@extensionType::A::@setter::foo2
              formalParameters
                #F16 requiredPositional isOriginDeclaration _ (nameOffset:101) (firstTokenOffset:97) (offset:101)
                  element: <testLibrary>::@extensionType::A::@setter::foo2::@formalParameter::_
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@extensionType::A::@setter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F14
          type: int
          setter: <testLibrary>::@extensionType::A::@setter::foo2
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      setters
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@setter::foo1
          firstFragment: #F12
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember isOriginDeclaration foo2
          reference: <testLibrary>::@extensionType::A::@setter::foo2
          firstFragment: #F15
          formalParameters
            #E2 requiredPositional _
              firstFragment: #F16
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo2
''');
  }

  test_setter_augmentation_chain() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  set foo1(int _) {}
  set foo2(int _) {}
}

augment extension type A(int it) {
  augment set foo1(int _) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
            #F7 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F8 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F10
              nextFragment: #F11
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F12
          setters
            #F13 hasImplicitReturnType isComplete isOriginDeclaration foo1 (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@extensionType::A::@setter::foo1
              formalParameters
                #F14 requiredPositional isOriginDeclaration _ (nameOffset:42) (firstTokenOffset:38) (offset:42)
                  element: <testLibrary>::@extensionType::A::@setter::foo1::@formalParameter::_
                  nextFragment: #F15
              nextFragment: #F16
            #F17 hasImplicitReturnType isComplete isOriginDeclaration foo2 (nameOffset:54) (firstTokenOffset:50) (offset:54)
              element: <testLibrary>::@extensionType::A::@setter::foo2
              formalParameters
                #F18 requiredPositional isOriginDeclaration _ (nameOffset:63) (firstTokenOffset:59) (offset:63)
                  element: <testLibrary>::@extensionType::A::@setter::foo2::@formalParameter::_
        #F2 isAugmentation extension type A (nameOffset:95) (firstTokenOffset:72) (offset:95)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F12
              previousFragment: #F3
          constructors
            #F11 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:95) (offset:95)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 95
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:101) (firstTokenOffset:97) (offset:101)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F8
          getters
            #F12 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
          setters
            #F16 hasImplicitReturnType isAugmentation isComplete isOriginDeclaration foo1 (nameOffset:121) (firstTokenOffset:109) (offset:121)
              element: <testLibrary>::@extensionType::A::@setter::foo1
              formalParameters
                #F15 requiredPositional isOriginDeclaration _ (nameOffset:130) (firstTokenOffset:126) (offset:130)
                  element: <testLibrary>::@extensionType::A::@setter::foo1::@formalParameter::_
                  previousFragment: #F14
              previousFragment: #F13
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@extensionType::A::@setter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F7
          type: int
          setter: <testLibrary>::@extensionType::A::@setter::foo2
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F9
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      setters
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@setter::foo1
          firstFragment: #F13
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F14
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember isOriginDeclaration foo2
          reference: <testLibrary>::@extensionType::A::@setter::foo2
          firstFragment: #F17
          formalParameters
            #E2 requiredPositional _
              firstFragment: #F18
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo2
''');
  }

  test_setter_augmentation_chain_fromField() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static set foo(int _) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F4
              nextFragment: #F5
            #F6 hasInitializer isOriginDeclaration isStatic foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              inducedGetter: #F7
              inducedSetter: #F8
          constructors
            #F9 isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F11
              nextFragment: #F12
          getters
            #F4 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F3
              nextFragment: #F13
            #F7 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              inducingVariable: #F6
          setters
            #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              inducingVariable: #F6
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  nextFragment: #F15
              nextFragment: #F16
        #F2 isAugmentation extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F5 isAugmentation isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              inducedGetter: #F13
              previousFragment: #F3
          constructors
            #F12 isAugmentation isComplete isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F11 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F10
              previousFragment: #F9
          getters
            #F13 isAugmentation isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@getter::it
              inducingVariable: #F5
              previousFragment: #F4
          setters
            #F16 hasImplicitReturnType isAugmentation isComplete isOriginDeclaration isStatic foo (nameOffset:108) (firstTokenOffset:89) (offset:108)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F15 requiredPositional isOriginDeclaration _ (nameOffset:116) (firstTokenOffset:112) (offset:116)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
                  previousFragment: #F14
              previousFragment: #F8
  extensionTypes
    isSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
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
        hasInitializer isOriginDeclaration isStatic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F10
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        isExtensionTypeMember isOriginVariable isStatic foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F14
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }
}

@reflectiveTest
class ExtensionTypeElementTest_fromBytes extends ExtensionTypeElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class ExtensionTypeElementTest_keepLinking extends ExtensionTypeElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
