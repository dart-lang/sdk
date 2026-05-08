// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotationTest);
    defineReflectiveTests(MiscellaneousTest);
    defineReflectiveTests(ModifiersTest);
    defineReflectiveTests(MultipleTypeTest);
    defineReflectiveTests(PunctuationTest);
    defineReflectiveTests(VarianceModifierTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Test how well the parser recovers when annotations are included in places
/// where they are not allowed.
@reflectiveTest
class AnnotationTest extends ParserDiagnosticsTest {
  void test_typeArgument() {
    var parseResult = parseStringWithErrors(r'''
const annotation = null;
class A<E> {}
class C {
  m() => new A<@annotation C>();
}
''');
    parseResult.assertErrors([error(diag.annotationOnTypeArgument, 64, 11)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: annotation
            equals: =
            initializer: NullLiteral
              literal: null
      semicolon: ;
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: E
          rightBracket: >
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: InstanceCreationExpression
                keyword: new
                constructorName: ConstructorName
                  type: NamedType
                    name: A
                    typeArguments: TypeArgumentList
                      leftBracket: <
                      arguments
                        NamedType
                          name: C
                      rightBracket: >
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
              semicolon: ;
        rightBracket: }
''');
  }
}

/// Test how well the parser recovers in other cases.
@reflectiveTest
class MiscellaneousTest extends ParserDiagnosticsTest {
  void test_classTypeAlias_withBody() {
    var parseResult = parseStringWithErrors(r'''
class B = Object with A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.expectedExecutable, 24, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: B
      equals: =
      superclass: NamedType
        name: Object
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: A
      semicolon: ; <synthetic>
''');
  }

  void test_getter_parameters() {
    var parseResult = parseStringWithErrors(r'''
int get g(x) => 0;
''');
    parseResult.assertErrors([
      error(diag.getterWithParameters, 9, 1), // Let's guess
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: int
      propertyKeyword: get
      name: g
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
''');
  }

  void test_identifier_afterNamedArgument() {
    var parseResult = parseStringWithErrors(r'''
a() {
  b(c: c(d: d(e: null f,),),);
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 28, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: a
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
                    token: b
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      NamedExpression
                        name: Label
                          label: SimpleIdentifier
                            token: c
                          colon: :
                        expression: MethodInvocation
                          methodName: SimpleIdentifier
                            token: c
                          argumentList: ArgumentList
                            leftParenthesis: (
                            arguments
                              NamedExpression
                                name: Label
                                  label: SimpleIdentifier
                                    token: d
                                  colon: :
                                expression: MethodInvocation
                                  methodName: SimpleIdentifier
                                    token: d
                                  argumentList: ArgumentList
                                    leftParenthesis: (
                                    arguments
                                      NamedExpression
                                        name: Label
                                          label: SimpleIdentifier
                                            token: e
                                          colon: :
                                        expression: NullLiteral
                                          literal: null
                                      SimpleIdentifier
                                        token: f
                                    rightParenthesis: )
                            rightParenthesis: )
                    rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_invalidRangeCheck() {
    var parseResult = parseStringWithErrors(r'''
f(x) {
  while (1 < x < 3) {}
}
''');
    parseResult.assertErrors([
      error(diag.equalityCannotBeEqualityOperand, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: BinaryExpression
                  leftOperand: BinaryExpression
                    leftOperand: IntegerLiteral
                      literal: 1
                    operator: <
                    rightOperand: SimpleIdentifier
                      token: x
                  operator: <
                  rightOperand: IntegerLiteral
                    literal: 3
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_listLiteralType() {
    var parseResult = parseStringWithErrors(r'''
List<int> ints = List<int>[];
''');
    parseResult.assertErrors([error(diag.literalWithClass, 17, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: List
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: int
            rightBracket: >
        variables
          VariableDeclaration
            name: ints
            equals: =
            initializer: ListLiteral
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: int
                rightBracket: >
              leftBracket: [
              rightBracket: ]
      semicolon: ;
''');
  }

  void test_mapLiteralType() {
    var parseResult = parseStringWithErrors(r'''
Map<int, int> map = Map<int, int>{};
''');
    parseResult.assertErrors([error(diag.literalWithClass, 20, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: Map
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: int
              NamedType
                name: int
            rightBracket: >
        variables
          VariableDeclaration
            name: map
            equals: =
            initializer: SetOrMapLiteral
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: int
                  NamedType
                    name: int
                rightBracket: >
              leftBracket: {
              rightBracket: }
              isMap: false
      semicolon: ;
''');
  }

  void test_mixin_using_with_clause() {
    var parseResult = parseStringWithErrors(r'''
mixin M {}
mixin N with M {}
''');
    parseResult.assertErrors([error(diag.mixinWithClause, 19, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
    MixinDeclaration
      mixinKeyword: mixin
      name: N
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_multipleRedirectingInitializers() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A() : this.a(), this.b();
  A.a() {}
  A.b() {}
}
''');
    parseResult.assertErrors([]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: A
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              RedirectingConstructorInvocation
                thisKeyword: this
                period: .
                constructorName: SimpleIdentifier
                  token: a
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
              RedirectingConstructorInvocation
                thisKeyword: this
                period: .
                constructorName: SimpleIdentifier
                  token: b
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: A
            period: .
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: A
            period: .
            name: b
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

  void test_parenInMapLiteral() {
    var parseResult = parseStringWithErrors(r'''
class C {}
final Map v = {
  'a': () => new C(),
  'b': () => new C()),
  'c': () => new C(),
};
''');
    parseResult.assertErrors([error(diag.expectedToken, 69, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: Map
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: SetOrMapLiteral
              leftBracket: {
              elements
                MapLiteralEntry
                  key: SimpleStringLiteral
                    literal: 'a'
                  separator: :
                  value: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: ExpressionFunctionBody
                      functionDefinition: =>
                      expression: InstanceCreationExpression
                        keyword: new
                        constructorName: ConstructorName
                          type: NamedType
                            name: C
                        argumentList: ArgumentList
                          leftParenthesis: (
                          rightParenthesis: )
                MapLiteralEntry
                  key: SimpleStringLiteral
                    literal: 'b'
                  separator: :
                  value: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: ExpressionFunctionBody
                      functionDefinition: =>
                      expression: InstanceCreationExpression
                        keyword: new
                        constructorName: ConstructorName
                          type: NamedType
                            name: C
                        argumentList: ArgumentList
                          leftParenthesis: (
                          rightParenthesis: )
              rightBracket: }
              isMap: false
      semicolon: ;
''');
  }
}

/// Test how well the parser recovers when extra modifiers are provided.
@reflectiveTest
class ModifiersTest extends ParserDiagnosticsTest {
  void test_classDeclaration_static() {
    var parseResult = parseStringWithErrors(r'''
static class A {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_methodDeclaration_const_getter() {
    var parseResult = parseStringWithErrors(r'''
main() {}
const int get foo => 499;
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 10, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: main
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    FunctionDeclaration
      returnType: NamedType
        name: int
      propertyKeyword: get
      name: foo
      functionExpression: FunctionExpression
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 499
          semicolon: ;
''');
  }

  void test_methodDeclaration_const_method() {
    var parseResult = parseStringWithErrors(r'''
main() {}
const int foo() => 499;
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 10, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: main
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    FunctionDeclaration
      returnType: NamedType
        name: int
      name: foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 499
          semicolon: ;
''');
  }

  void test_methodDeclaration_const_setter() {
    var parseResult = parseStringWithErrors(r'''
main() {}
const set foo(v) => 499;
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 10, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: main
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    FunctionDeclaration
      propertyKeyword: set
      name: foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: v
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 499
          semicolon: ;
''');
  }
}

/// Test how well the parser recovers when multiple type annotations are
/// provided.
@reflectiveTest
class MultipleTypeTest extends ParserDiagnosticsTest {
  void test_topLevelVariable() {
    var parseResult = parseStringWithErrors(r'''
String void bar() { }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 0, 6),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: String
      semicolon: ; <synthetic>
    FunctionDeclaration
      returnType: NamedType
        name: void
      name: bar
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
}

/// Test how well the parser recovers when there is extra punctuation.
@reflectiveTest
class PunctuationTest extends ParserDiagnosticsTest {
  void test_extraComma_extendsClause() {
    var parseResult = parseStringWithErrors(r'''
class A { }
class B { }
class Foo extends A, B {
  Foo() { }
}
''');
    parseResult.assertErrors([error(diag.multipleExtendsClauses, 43, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: Foo
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: A
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: Foo
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

  void test_extraSemicolon_afterLastClassMember() {
    var parseResult = parseStringWithErrors(r'''
class C {
  foo() {};
}
''');
    parseResult.assertErrors([error(diag.expectedClassMember, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
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

  void test_extraSemicolon_afterLastTopLevelMember() {
    var parseResult = parseStringWithErrors(r'''
foo() {};
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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

  void test_extraSemicolon_beforeFirstClassMember() {
    var parseResult = parseStringWithErrors(r'''
class C {
  ;foo() {}
}
''');
    parseResult.assertErrors([error(diag.expectedClassMember, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
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

  void test_extraSemicolon_beforeFirstTopLevelMember() {
    var parseResult = parseStringWithErrors(r'''
;foo() {}
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 0, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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

  void test_extraSemicolon_betweenClassMembers() {
    var parseResult = parseStringWithErrors(r'''
class C {
  foo() {};
  bar() {}
}
''');
    parseResult.assertErrors([error(diag.expectedClassMember, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            name: foo
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
          MethodDeclaration
            name: bar
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

  void test_extraSemicolon_betweenTopLevelMembers() {
    var parseResult = parseStringWithErrors(r'''
foo() {};
bar() {}
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    FunctionDeclaration
      name: bar
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
}

/// Test how well the parser recovers when there is extra variance modifiers.
@reflectiveTest
class VarianceModifierTest extends ParserDiagnosticsTest {
  void test_extraModifier_inClass() {
    var parseResult = parseStringWithErrors(r'''
class A<in out X> {}
''');
    parseResult.assertErrors([error(diag.multipleVarianceModifiers, 11, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              varianceKeyword: in
              name: X
          rightBracket: >
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }
}
