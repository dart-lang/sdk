// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelFunctionParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TopLevelFunctionParserTest extends ParserDiagnosticsTest {
  test_function_abstract() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
abstract void foo() {}
// [diag.extraneousModifier][column 1][length 8] Can't have modifier 'abstract' here.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
''');
  }

  test_function_abstract_language305() {
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.5
abstract void foo() {}
// [diag.extraneousModifier][column 1][length 8] Can't have modifier 'abstract' here.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
''');
  }

  test_function_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment void foo() {}
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  returnType: NamedType
    name: void
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
''');
  }

  test_function_augment_body_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment void foo();
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  returnType: NamedType
    name: void
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_function_augment_external() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment external void foo();
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  externalKeyword: external
  returnType: NamedType
    name: void
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_function_augment_language305() {
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.5
augment void foo() {}
// [diag.missingConstFinalVarOrType][column 1][length 7] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
''');
  }

  test_function_body_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void foo();
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_function_body_empty_language305() {
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.5
void foo();
//        ^
// [diag.missingFunctionBody] A function body must be provided.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_function_external_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
external augment void foo();
//       ^^^^^^^
// [diag.modifierOutOfOrder] The modifier 'augment' should be before the modifier 'external'.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  externalKeyword: external
  returnType: NamedType
    name: void
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_getter_abstract() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
abstract int get foo {}
// [diag.extraneousModifier][column 1][length 8] Can't have modifier 'abstract' here.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: foo
  functionExpression: FunctionExpression
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
''');
  }

  test_getter_abstract_language305() {
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.5
abstract int get foo {}
// [diag.extraneousModifier][column 1][length 8] Can't have modifier 'abstract' here.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: foo
  functionExpression: FunctionExpression
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
''');
  }

  test_getter_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment int get foo => 0;
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: foo
  functionExpression: FunctionExpression
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 0
      semicolon: ;
''');
  }

  test_getter_augment_body_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment int get foo;
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: foo
  functionExpression: FunctionExpression
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_getter_augment_external() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment external int get foo;
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  externalKeyword: external
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: foo
  functionExpression: FunctionExpression
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_getter_augment_language305() {
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.5
augment int get foo => 0;
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  propertyKeyword: get
  name: foo
  functionExpression: FunctionExpression
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 0
      semicolon: ;
''');
  }

  test_getter_body_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
int get foo;
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: foo
  functionExpression: FunctionExpression
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_getter_body_empty_language305() {
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.5
int get foo;
//         ^
// [diag.missingFunctionBody] A function body must be provided.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: foo
  functionExpression: FunctionExpression
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_recovery_body_issue56355() {
    // https://github.com/dart-lang/sdk/issues/56355
    var parseResult = parseTestCodeWithDiagnostics(r'''
void get() {
  http.Response response = http2
//                         ^^^^^
// [diag.expectedToken] Expected to find ';'.
}
''');

    // Note, there is a cycle that should not be there.
    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(
      node,
      withTokenPreviousNext: true,
      withOffsets: true,
      r'''
FunctionDeclaration
  returnType: NamedType
    name: T0 void @0
      next: T1 |get|
  name: T1 get @5
    previous: T0 |void|
    next: T2 |(|
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: T2 ( @8
        previous: T1 |get|
        next: T3 |)|
      rightParenthesis: T3 ) @9
        previous: T2 |(|
        next: T4 |{|
    body: BlockFunctionBody
      block: Block
        leftBracket: T4 { @11
          previous: T3 |)|
          next: T5 |http|
        statements
          ExpressionStatement
            expression: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: T5 http @15
                  previous: T4 |{|
                  next: T6 |.|
              period: T6 . @19
                previous: T5 |http|
                next: T7 |Response|
              identifier: SimpleIdentifier
                token: T7 Response @20
                  previous: T6 |.|
                  next: T8 |;|
            semicolon: T8 ; @46 <synthetic>
              previous: T7 |Response|
              next: T9 |}|
        rightBracket: T9 } @46
          previous: T8 |;|
          next: T10 ||
''',
    );
  }

  test_setter_abstract() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
abstract set foo(int _) {}
// [diag.extraneousModifier][column 1][length 8] Can't have modifier 'abstract' here.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  propertyKeyword: set
  name: foo
  functionExpression: FunctionExpression
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
''');
  }

  test_setter_abstract_language305() {
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.5
abstract set foo(int _) {}
// [diag.extraneousModifier][column 1][length 8] Can't have modifier 'abstract' here.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  propertyKeyword: set
  name: foo
  functionExpression: FunctionExpression
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
''');
  }

  test_setter_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment set foo(int _) {}
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  propertyKeyword: set
  name: foo
  functionExpression: FunctionExpression
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
''');
  }

  test_setter_augment_body_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment set foo(int _);
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  propertyKeyword: set
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: _
      rightParenthesis: )
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_setter_augment_external() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment external set foo(int _);
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  externalKeyword: external
  propertyKeyword: set
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: _
      rightParenthesis: )
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_setter_augment_language305() {
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.5
augment set foo(int _) {}
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: augment
  propertyKeyword: set
  name: foo
  functionExpression: FunctionExpression
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
''');
  }

  test_setter_body_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
set foo(int _);
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  propertyKeyword: set
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: _
      rightParenthesis: )
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_setter_body_empty_language305() {
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.5
set foo(int _);
//            ^
// [diag.missingFunctionBody] A function body must be provided.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  propertyKeyword: set
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: _
      rightParenthesis: )
    body: EmptyFunctionBody
      semicolon: ;
''');
  }

  test_setter_formalParameters_absent() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
set foo {}
//  ^^^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
FunctionDeclaration
  propertyKeyword: set @0
  name: foo @4
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: ( @8 <synthetic>
      parameter: RegularFormalParameter
        name: <empty> @8 <synthetic>
      rightParenthesis: ) @8 <synthetic>
    body: BlockFunctionBody
      block: Block
        leftBracket: { @8
        rightBracket: } @9
''');
  }

  test_setter_formalParameters_optionalNamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
set foo({a}) {}
//  ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
FunctionDeclaration
  propertyKeyword: set @0
  name: foo @4
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: ( @7
      parameter: RegularFormalParameter
        name: a @9
      rightParenthesis: ) @11
    body: BlockFunctionBody
      block: Block
        leftBracket: { @13
        rightBracket: } @14
''');
  }

  test_setter_formalParameters_optionalPositional() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
set foo([a]) {}
//  ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
FunctionDeclaration
  propertyKeyword: set @0
  name: foo @4
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: ( @7
      parameter: RegularFormalParameter
        name: a @9
      rightParenthesis: ) @11
    body: BlockFunctionBody
      block: Block
        leftBracket: { @13
        rightBracket: } @14
''');
  }

  test_setter_formalParameters_requiredPositional_three() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
set foo(a, b, c) {}
//  ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
FunctionDeclaration
  propertyKeyword: set @0
  name: foo @4
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: ( @7
      parameter: RegularFormalParameter
        name: a @8
      rightParenthesis: ) @15
    body: BlockFunctionBody
      block: Block
        leftBracket: { @17
        rightBracket: } @18
''');
  }

  test_setter_formalParameters_zero() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
set foo() {}
//  ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
''');

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
FunctionDeclaration
  propertyKeyword: set @0
  name: foo @4
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: ( @7
      parameter: RegularFormalParameter
        name: <empty> @8 <synthetic>
      rightParenthesis: ) @8
    body: BlockFunctionBody
      block: Block
        leftBracket: { @10
        rightBracket: } @11
''');
  }
}
