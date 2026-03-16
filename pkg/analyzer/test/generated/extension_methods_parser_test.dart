// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionMethodsParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExtensionMethodsParserTest extends ParserDiagnosticsTest {
  void test_complex_extends() {
    var parseResult = parseStringWithErrors(r'''
extension E extends A with B, C implements D { }
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 12, 7),
      error(diag.unexpectedToken, 22, 4),
      error(diag.unexpectedToken, 28, 1),
      error(diag.unexpectedToken, 32, 10),
    ]);

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: extends
    extendedType: NamedType
      name: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_complex_implements() {
    var parseResult = parseStringWithErrors(r'''
extension E implements C, D { }
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 12, 10),
      error(diag.unexpectedToken, 24, 1),
    ]);

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: implements
    extendedType: NamedType
      name: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_complex_type() {
    var parseResult = parseStringWithErrors(r'''
extension E on C<T> {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: T
        rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_complex_type2() {
    var parseResult = parseStringWithErrors(r'''
extension E<T> on C<T> {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: T
        rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_complex_type2_no_name() {
    var parseResult = parseStringWithErrors(r'''
extension<T> on C<T> {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: T
        rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_constructor_named() {
    var parseResult = parseStringWithErrors('''
extension E on C {
  E.named();
}
class C {}
''');
    parseResult.assertErrors([error(diag.extensionDeclaresConstructor, 21, 1)]);

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_constructor_unnamed() {
    var parseResult = parseStringWithErrors('''
extension E on C {
  E();
}
class C {}
''');
    parseResult.assertErrors([error(diag.extensionDeclaresConstructor, 21, 1)]);

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_missing_on() {
    var parseResult = parseStringWithErrors(r'''
extension E
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedTypeName, 12, 0),
      error(diag.expectedExtensionBody, 12, 0),
    ]);

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on <synthetic>
    extendedType: NamedType
      name: <empty> <synthetic>
  body: BlockClassBody
    leftBracket: { <synthetic>
    rightBracket: } <synthetic>
''');
  }

  void test_missing_on_withBlock() {
    var parseResult = parseStringWithErrors(r'''
extension E {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedTypeName, 12, 1),
    ]);

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on <synthetic>
    extendedType: NamedType
      name: <empty> <synthetic>
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_missing_on_withClassAndBlock() {
    var parseResult = parseStringWithErrors(r'''
extension E C {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on <synthetic>
    extendedType: NamedType
      name: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parse_toplevel_member_called_late_calling_self() {
    var parseResult = parseStringWithErrors(r'''
void late() {
  late();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: late
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        statements
          ExpressionStatement
            expression: MethodInvocation
              methodName: SimpleIdentifier
                token: late
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
            semicolon: ;
        rightBracket: }
''');
  }

  void test_simple() {
    var parseResult = parseStringWithErrors(r'''
extension E on C {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_simple_extends() {
    var parseResult = parseStringWithErrors(r'''
extension E extends C { }
''');
    parseResult.assertErrors([error(diag.expectedInstead, 12, 7)]);

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: extends
    extendedType: NamedType
      name: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_simple_implements() {
    var parseResult = parseStringWithErrors(r'''
extension E implements C { }
''');
    parseResult.assertErrors([error(diag.expectedInstead, 12, 10)]);

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: implements
    extendedType: NamedType
      name: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_simple_no_name() {
    var parseResult = parseStringWithErrors(r'''
extension on C {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_simple_with() {
    var parseResult = parseStringWithErrors(r'''
extension E with C { }
''');
    parseResult.assertErrors([error(diag.expectedInstead, 12, 4)]);

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: with
    extendedType: NamedType
      name: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_void_type() {
    var parseResult = parseStringWithErrors(r'''
extension E on void {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: void
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }
}
