// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclarationParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExtensionDeclarationParserTest extends ParserDiagnosticsTest {
  test_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension E {}
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension E<T> {}
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_hasOnClause() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension E on int {}
//                  ^^
// [diag.extensionAugmentationHasOnClause] Extension augmentations can't have 'on' clauses.
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_body_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
}
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        returnType: NamedType
          name: int
        propertyKeyword: get
        name: foo
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
    rightBracket: }
''');
  }

  test_body_method() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        returnType: NamedType
          name: void
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');
  }

  test_body_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _) {}
}
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        propertyKeyword: set
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: _
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');
  }

  test_declaration_emptyBody() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on int;
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: EmptyClassBody
    semicolon: ;
''');
  }

  test_emptyBody_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension E on int;
//                ^
// [diag.experimentNotEnabled] This requires the 'primary-constructors' language feature to be enabled.
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: EmptyClassBody
    semicolon: ;
''');
  }

  test_field_augment_static() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension E {
  augment static int x = 0;
}
''');
    assertParsedNodeText(parseResult.findNode.singleExtensionDeclaration, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        augmentKeyword: augment
        staticKeyword: static
        fields: VariableDeclarationList
          type: NamedType
            name: int
          variables
            VariableDeclaration
              name: x
              equals: =
              initializer: IntegerLiteral
                literal: 0
        semicolon: ;
    rightBracket: }
''');
  }

  test_field_augment_static_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension E {
  augment static final int x = 0;
}
''');
    assertParsedNodeText(parseResult.findNode.singleExtensionDeclaration, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        augmentKeyword: augment
        staticKeyword: static
        fields: VariableDeclarationList
          keyword: final
          type: NamedType
            name: int
          variables
            VariableDeclaration
              name: x
              equals: =
              initializer: IntegerLiteral
                literal: 0
        semicolon: ;
    rightBracket: }
''');
  }

  test_getter_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension E {
  augment int get foo => 0;
}
''');
    assertParsedNodeText(parseResult.findNode.singleExtensionDeclaration, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        returnType: NamedType
          name: int
        propertyKeyword: get
        name: foo
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
    rightBracket: }
''');
  }

  test_getter_augment_static() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension E {
  augment static int get foo => 0;
}
''');
    assertParsedNodeText(parseResult.findNode.singleExtensionDeclaration, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        modifierKeyword: static
        returnType: NamedType
          name: int
        propertyKeyword: get
        name: foo
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
    rightBracket: }
''');
  }

  test_method_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension E {
  augment void foo() {}
}
''');
    assertParsedNodeText(parseResult.findNode.singleExtensionDeclaration, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        returnType: NamedType
          name: void
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');
  }

  test_method_augment_static() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension E {
  augment static void foo() {}
}
''');
    assertParsedNodeText(parseResult.findNode.singleExtensionDeclaration, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        modifierKeyword: static
        returnType: NamedType
          name: void
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');
  }

  void test_onClause_recordType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on (int, int) {}
''');

    var node = parseResult.findNode.extensionDeclaration('extension E');
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension @0
  name: E @10
  onClause: ExtensionOnClause
    onKeyword: on @12
    extendedType: RecordTypeAnnotation
      leftParenthesis: ( @15
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int @16
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int @21
      rightParenthesis: ) @24
  body: BlockClassBody
    leftBracket: { @26
    rightBracket: } @27
''', withOffsets: true);
  }

  test_operator_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension E {
  augment int operator+(int other) => 0;
}
''');
    assertParsedNodeText(parseResult.findNode.singleExtensionDeclaration, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        returnType: NamedType
          name: int
        operatorKeyword: operator
        name: +
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: other
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
    rightBracket: }
''');
  }

  test_primaryConstructor_const_typeName_formalParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension const A() on int {}
//        ^^^^^
// [diag.extensionPrimaryConstructor] Extensions can't have primary constructors.
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: A
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_const_typeName_formalParameters_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart=3.10
extension const A() on int {}
//        ^^^^^
// [diag.unexpectedToken] Unexpected text 'const'.
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: A
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_const_typeName_noFormalParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension const A on int {}
//        ^^^^^
// [diag.extensionPrimaryConstructor] Extensions can't have primary constructors.
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: A
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_const_typeName_noFormalParameters_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart=3.10
extension const A on int {}
//        ^^^^^
// [diag.unexpectedToken] Unexpected text 'const'.
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: A
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_const_typeName_periodName_formalParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension const A.name() on int {}
//        ^^^^^
// [diag.extensionPrimaryConstructor] Extensions can't have primary constructors.
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: A
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_const_typeName_periodName_formalParameters_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart=3.10
extension const A.name() on int {}
//        ^^^^^
// [diag.unexpectedToken] Unexpected text 'const'.
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: A
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_typeName_formalParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension A() on int {}
//         ^
// [diag.extensionPrimaryConstructor] Extensions can't have primary constructors.
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: A
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_typeName_formalParameters_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart=3.10
extension A() on int {}
//         ^
// [diag.unexpectedToken] Unexpected text '('.
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: A
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_typeName_periodName_formalParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension A.name() on int {}
//         ^
// [diag.extensionPrimaryConstructor] Extensions can't have primary constructors.
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: A
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_typeName_periodName_formalParameters_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart=3.10
extension A.name() on int {}
//         ^
// [diag.unexpectedToken] Unexpected text '.'.
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: A
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructorBody() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension A on int {
  this;
}
''');

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: A
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    members
      PrimaryConstructorBody
        thisKeyword: this
        body: EmptyFunctionBody
          semicolon: ;
    rightBracket: }
''');
  }

  test_setter_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension E {
  augment set foo(int x) {}
}
''');
    assertParsedNodeText(parseResult.findNode.singleExtensionDeclaration, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        propertyKeyword: set
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');
  }

  test_setter_augment_static() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension E {
  augment static set foo(int x) {}
}
''');
    assertParsedNodeText(parseResult.findNode.singleExtensionDeclaration, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        modifierKeyword: static
        propertyKeyword: set
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');
  }
}
