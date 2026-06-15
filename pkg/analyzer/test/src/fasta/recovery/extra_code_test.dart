// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
const annotation = null;
class A<E> {}
class C {
  m() => new A<@annotation C>();
//             ^^^^^^^^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class B = Object with A {}
//                    ^
// [diag.expectedToken] Expected to find ';'.
//                      ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
int get g(x) => 0;
//       ^
// [diag.getterWithParameters] Getters must be declared without a parameter list.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
a() {
  b(c: c(d: d(e: null f,),),);
//                    ^
// [diag.expectedToken] Expected to find ','.
}
''');
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
                      NamedArgument
                        name: c
                        colon: :
                        argumentExpression: MethodInvocation
                          methodName: SimpleIdentifier
                            token: c
                          argumentList: ArgumentList
                            leftParenthesis: (
                            arguments
                              NamedArgument
                                name: d
                                colon: :
                                argumentExpression: MethodInvocation
                                  methodName: SimpleIdentifier
                                    token: d
                                  argumentList: ArgumentList
                                    leftParenthesis: (
                                    arguments
                                      NamedArgument
                                        name: e
                                        colon: :
                                        argumentExpression: NullLiteral
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
  while (1 < x < 3) {}
//             ^
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<int> ints = List<int>[];
//               ^^^^
// [diag.literalWithClass] A list literal can't be prefixed by 'List'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
Map<int, int> map = Map<int, int>{};
//                  ^^^
// [diag.literalWithClass] A map literal can't be prefixed by 'Map'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin M {}
mixin N with M {}
//      ^^^^
// [diag.mixinWithClause] A mixin can't have a with clause.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A() : this.a(), this.b();
  A.a() {}
  A.b() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {}
final Map v = {
  'a': () => new C(),
  'b': () => new C()),
//                  ^
// [diag.expectedToken] Expected to find '}'.
  'c': () => new C(),
};
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
static class A {}
// [diag.extraneousModifier][column 1][length 6] Can't have modifier 'static' here.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
main() {}
const int get foo => 499;
// [diag.extraneousModifier][column 1][length 5] Can't have modifier 'const' here.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
main() {}
const int foo() => 499;
// [diag.extraneousModifier][column 1][length 5] Can't have modifier 'const' here.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
main() {}
const set foo(v) => 499;
// [diag.extraneousModifier][column 1][length 5] Can't have modifier 'const' here.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
String void bar() { }
// [diag.missingConstFinalVarOrType][column 1][length 6] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken][column 1][length 6] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A { }
class B { }
class Foo extends A, B {
//                 ^
// [diag.multipleExtendsClauses] Each class definition can have at most one extends clause.
  Foo() { }
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  foo() {};
//        ^
// [diag.expectedClassMember] Expected a class member.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
foo() {};
//      ^
// [diag.unexpectedToken] Unexpected text ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  ;foo() {}
//^
// [diag.expectedClassMember] Expected a class member.
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
;foo() {}
// [diag.unexpectedToken][column 1][length 1] Unexpected text ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  foo() {};
//        ^
// [diag.expectedClassMember] Expected a class member.
  bar() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
foo() {};
//      ^
// [diag.unexpectedToken] Unexpected text ';'.
bar() {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A<in out X> {}
//         ^^^
// [diag.multipleVarianceModifiers] Each type parameter can have at most one variance modifier.
''');
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
