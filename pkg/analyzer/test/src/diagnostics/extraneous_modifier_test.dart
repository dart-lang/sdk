// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtraneousModifierTest);
  });
}

@reflectiveTest
class ExtraneousModifierTest extends ParserDiagnosticsTest {
  test_class_constructor_formalParameter_requiredPositional_const() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(const a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 14, 5)]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      keyword: const
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_formalParameter_requiredPositional_final() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(final a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 14, 5)]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      keyword: final
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_formalParameter_requiredPositional_final_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
class A {
  A(final a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      keyword: final
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_formalParameter_requiredPositional_var() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(var a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 14, 3)]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      keyword: var
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_formalParameter_requiredPositional_var_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
class A {
  A(var a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      keyword: var
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_superFormalParameter_requiredPositional_const() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(const super.a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 14, 5)]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SuperFormalParameter
      keyword: const
      superKeyword: super
      period: .
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_superFormalParameter_requiredPositional_final() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(final super.a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 14, 5)]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SuperFormalParameter
      keyword: final
      superKeyword: super
      period: .
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_constructor_superFormalParameter_requiredPositional_var() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(var super.a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 14, 3)]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SuperFormalParameter
      keyword: var
      superKeyword: super
      period: .
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_class_method_formalParameter_optionalNamed_final() {
    var parseResult = parseStringWithErrors(r'''
class A {
  void foo({final int a}) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 22, 5)]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: DefaultFormalParameter
      parameter: SimpleFormalParameter
        keyword: final
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
    var parseResult = parseStringWithErrors(r'''
class A {
  void foo({var int a}) {}
}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifier, 22, 3),
      error(diag.varAndType, 22, 3),
    ]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: DefaultFormalParameter
      parameter: SimpleFormalParameter
        keyword: var
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
    var parseResult = parseStringWithErrors(r'''
class A {
  void foo({var a}) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 22, 3)]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: DefaultFormalParameter
      parameter: SimpleFormalParameter
        keyword: var
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
    var parseResult = parseStringWithErrors(r'''
class A {
  void foo([final int a]) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 22, 5)]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: [
    parameter: DefaultFormalParameter
      parameter: SimpleFormalParameter
        keyword: final
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
    var parseResult = parseStringWithErrors(r'''
class A {
  void foo([var int a]) {}
}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifier, 22, 3),
      error(diag.varAndType, 22, 3),
    ]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: [
    parameter: DefaultFormalParameter
      parameter: SimpleFormalParameter
        keyword: var
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
    var parseResult = parseStringWithErrors(r'''
class A {
  void foo([var a]) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 22, 3)]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: [
    parameter: DefaultFormalParameter
      parameter: SimpleFormalParameter
        keyword: var
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
    var parseResult = parseStringWithErrors(r'''
class A {
  void foo({required final int a}) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 31, 5)]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: DefaultFormalParameter
      parameter: SimpleFormalParameter
        requiredKeyword: required
        keyword: final
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
    var parseResult = parseStringWithErrors(r'''
class A {
  void foo({required var int a}) {}
}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifier, 31, 3),
      error(diag.varAndType, 31, 3),
    ]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: DefaultFormalParameter
      parameter: SimpleFormalParameter
        requiredKeyword: required
        keyword: var
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
    var parseResult = parseStringWithErrors(r'''
class A {
  void foo({required var a}) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 31, 3)]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: DefaultFormalParameter
      parameter: SimpleFormalParameter
        requiredKeyword: required
        keyword: var
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
    var parseResult = parseStringWithErrors(r'''
class A {
  void foo(final int a) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 21, 5)]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      keyword: final
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
    var parseResult = parseStringWithErrors(r'''
class A {
  void foo(var int a) {}
}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifier, 21, 3),
      error(diag.varAndType, 21, 3),
    ]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      keyword: var
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
    var parseResult = parseStringWithErrors(r'''
class A {
  void foo(var a) {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 21, 3)]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      keyword: var
      name: a
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_closure_formalParameter_final() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  (final value) => null;
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 14, 5)]);

    var node = parseResult.findNode.functionExpression('(final');
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      keyword: final
      name: value
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
''');
  }

  test_closure_formalParameter_var() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  (var value) => null;
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 14, 3)]);

    var node = parseResult.findNode.functionExpression('(var');
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      keyword: var
      name: value
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
''');
  }
}
