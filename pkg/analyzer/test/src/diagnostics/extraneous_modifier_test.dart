// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/node_text_expectations.dart';
import 'parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtraneousModifierTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExtraneousModifierTest extends ParserDiagnosticsTest {
  test_class_constructor_formalParameter_requiredPositional_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(const a);
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: const
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_formalParameter_requiredPositional_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(final a);
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: final
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_formalParameter_requiredPositional_final_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
class A {
  A(final a);
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: final
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_formalParameter_requiredPositional_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(var a);
//  ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: var
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_formalParameter_requiredPositional_var_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
class A {
  A(var a);
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: var
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_superFormalParameter_requiredPositional_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(const super.a);
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SuperFormalParameter
      constFinalOrVarKeyword: const
      superKeyword: super
      period: .
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_superFormalParameter_requiredPositional_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(final super.a);
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SuperFormalParameter
      constFinalOrVarKeyword: final
      superKeyword: super
      period: .
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_superFormalParameter_requiredPositional_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(var super.a);
//  ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SuperFormalParameter
      constFinalOrVarKeyword: var
      superKeyword: super
      period: .
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_method_formalParameter_optionalNamed_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void foo({final int a}) {}
//          ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: final
      type: NamedType
        name: int
      name: a
    rightDelimiter: }
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_class_method_formalParameter_optionalNamed_var_hasType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void foo({var int a}) {}
//          ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: var
      type: NamedType
        name: int
      name: a
    rightDelimiter: }
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_class_method_formalParameter_optionalNamed_var_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void foo({var a}) {}
//          ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: var
      name: a
    rightDelimiter: }
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_class_method_formalParameter_optionalPositional_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void foo([final int a]) {}
//          ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: [
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: final
      type: NamedType
        name: int
      name: a
    rightDelimiter: ]
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_class_method_formalParameter_optionalPositional_var_hasType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void foo([var int a]) {}
//          ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: [
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: var
      type: NamedType
        name: int
      name: a
    rightDelimiter: ]
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_class_method_formalParameter_optionalPositional_var_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void foo([var a]) {}
//          ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: [
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: var
      name: a
    rightDelimiter: ]
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_class_method_formalParameter_requiredNamed_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void foo({required final int a}) {}
//                   ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: RegularFormalParameter
      requiredKeyword: required
      constFinalOrVarKeyword: final
      type: NamedType
        name: int
      name: a
    rightDelimiter: }
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_class_method_formalParameter_requiredNamed_var_hasType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void foo({required var int a}) {}
//                   ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: RegularFormalParameter
      requiredKeyword: required
      constFinalOrVarKeyword: var
      type: NamedType
        name: int
      name: a
    rightDelimiter: }
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_class_method_formalParameter_requiredNamed_var_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void foo({required var a}) {}
//                   ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: RegularFormalParameter
      requiredKeyword: required
      constFinalOrVarKeyword: var
      name: a
    rightDelimiter: }
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_class_method_formalParameter_requiredPositional_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void foo(final int a) {}
//         ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: final
      type: NamedType
        name: int
      name: a
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_class_method_formalParameter_requiredPositional_var_hasType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void foo(var int a) {}
//         ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: var
      type: NamedType
        name: int
      name: a
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_class_method_formalParameter_requiredPositional_var_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void foo(var a) {}
//         ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: var
      name: a
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_closure_formalParameter_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  (final value) => null;
// ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

    var node = parseResult.findNode.functionExpression('(final');
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: final
      name: value
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
''');
  }

  test_closure_formalParameter_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  (var value) => null;
// ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
}
''');

    var node = parseResult.findNode.functionExpression('(var');
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: var
      name: value
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
''');
  }
}
