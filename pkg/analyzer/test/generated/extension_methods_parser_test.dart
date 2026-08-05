// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E extends A with B, C implements D { }
//          ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//                    ^^^^
// [diag.unexpectedToken] Unexpected text 'with'.
//                          ^
// [diag.unexpectedToken] Unexpected text ','.
//                              ^^^^^^^^^^
// [diag.unexpectedToken] Unexpected text 'implements'.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E implements C, D { }
//          ^^^^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//                      ^
// [diag.unexpectedToken] Unexpected text ','.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on C<T> {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E<T> on C<T> {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension<T> on C<T> {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics('''
extension E on C {
  E.named();
//^
// [diag.extensionDeclaresConstructor] Extensions can't declare constructors.
}
class C {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics('''
extension E on C {
  E();
//^
// [diag.extensionDeclaresConstructor] Extensions can't declare constructors.
}
class C {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E
//        ^
// [diag.expectedToken] Expected to find 'on'.
//         ^
// [diag.expectedTypeName][column 12][length 0] Expected a type name.
// [diag.expectedExtensionBody][column 12][length 0] An extension declaration must have a body, even if it is empty.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E {}
//        ^
// [diag.expectedToken] Expected to find 'on'.
//          ^
// [diag.expectedTypeName] Expected a type name.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E C {}
//        ^
// [diag.expectedToken] Expected to find 'on'.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void late() {
  late();
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on C {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E extends C { }
//          ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E implements C { }
//          ^^^^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension on C {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E with C { }
//          ^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on void {}
''');

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
