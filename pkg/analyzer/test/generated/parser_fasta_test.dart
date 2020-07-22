// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/async_modifier.dart';
import 'package:_fe_analyzer_shared/src/parser/parser.dart' as fasta;
import 'package:_fe_analyzer_shared/src/scanner/error_token.dart'
    show ErrorToken;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' as fasta;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration, ScannerResult, scanString;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' as analyzer;
import 'package:analyzer/dart/ast/token.dart'
    show Token, TokenType, LanguageVersionToken;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/fasta/ast_builder.dart';
import 'package:analyzer/src/generated/parser.dart' as analyzer;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:pub_semver/src/version.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'parser_fasta_listener.dart';
import 'parser_test.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassMemberParserTest_Fasta);
    defineReflectiveTests(ExtensionMethodsParserTest_Fasta);
    defineReflectiveTests(CollectionLiteralParserTest);
    defineReflectiveTests(ComplexParserTest_Fasta);
    defineReflectiveTests(ErrorParserTest_Fasta);
    defineReflectiveTests(ExpressionParserTest_Fasta);
    defineReflectiveTests(FormalParameterParserTest_Fasta);
    defineReflectiveTests(NNBDParserTest_Fasta);
    defineReflectiveTests(RecoveryParserTest_Fasta);
    defineReflectiveTests(SimpleParserTest_Fasta);
    defineReflectiveTests(StatementParserTest_Fasta);
    defineReflectiveTests(TopLevelParserTest_Fasta);
    defineReflectiveTests(VarianceParserTest_Fasta);
  });
}

/// Type of the "parse..." methods defined in the Fasta parser.
typedef ParseFunction = analyzer.Token Function(analyzer.Token token);

@reflectiveTest
class ClassMemberParserTest_Fasta extends FastaParserTestCase
    with ClassMemberParserTestMixin {
  final tripleShift = FeatureSet.forTesting(
      sdkVersion: '2.0.0', additionalFeatures: [Feature.triple_shift]);

  void test_parse_member_called_late() {
    CompilationUnitImpl unit = parseCompilationUnit(
        'class C { void late() { new C().late(); } }',
        featureSet: nonNullable);
    ClassDeclaration declaration = unit.declarations[0];
    MethodDeclaration method = declaration.members[0];

    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name.name, 'late');
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);

    BlockFunctionBody body = method.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;
    expect(invocation.operator.lexeme, '.');
    expect(invocation.toSource(), 'new C().late()');
  }

  void test_parseClassMember_finalAndCovariantLateWithInitializer() {
    createParser(
      'covariant late final int f = 0;',
      featureSet: nonNullable,
    );
    parser.parseClassMember('C');
    assertErrors(errors: [
      expectedError(
          ParserErrorCode.FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER, 0, 9)
    ]);
  }

  void test_parseClassMember_operator_gtgtgt() {
    CompilationUnitImpl unit = parseCompilationUnit(
        'class C { bool operator >>>(other) => false; }',
        featureSet: tripleShift);
    ClassDeclaration declaration = unit.declarations[0];
    MethodDeclaration method = declaration.members[0];

    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name.name, '>>>');
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_gtgtgteq() {
    CompilationUnitImpl unit = parseCompilationUnit(
        'class C { foo(int value) { x >>>= value; } }',
        featureSet: tripleShift);
    ClassDeclaration declaration = unit.declarations[0];
    MethodDeclaration method = declaration.members[0];
    BlockFunctionBody blockFunctionBody = method.body;
    NodeList<Statement> statements = blockFunctionBody.block.statements;
    expect(statements, hasLength(1));
    ExpressionStatement statement = statements[0];
    AssignmentExpression assignment = statement.expression;
    SimpleIdentifier leftHandSide = assignment.leftHandSide;
    expect(leftHandSide.name, 'x');
    expect(assignment.operator.lexeme, '>>>=');
    SimpleIdentifier rightHandSide = assignment.rightHandSide;
    expect(rightHandSide.name, 'value');
  }

  void test_parseConstructor_invalidInitializer() {
    // https://github.com/dart-lang/sdk/issues/37693
    parseCompilationUnit('class C{ C() : super() * (); }', errors: [
      expectedError(ParserErrorCode.INVALID_INITIALIZER, 15, 12),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
    ]);
  }

  void test_parseConstructor_nullSuperArgList_openBrace_37735() {
    // https://github.com/dart-lang/sdk/issues/37735
    var unit = parseCompilationUnit('class{const():super.{n', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 5, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 11, 1),
      expectedError(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 11, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 20, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 20, 1),
      expectedError(ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY, 20, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 21, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 22, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 22, 1),
    ]);
    var classDeclaration = unit.declarations[0] as ClassDeclaration;
    var constructor = classDeclaration.members[0] as ConstructorDeclaration;
    var invocation = constructor.initializers[0] as SuperConstructorInvocation;
    expect(invocation.argumentList.arguments, hasLength(0));
  }

  void test_parseConstructor_operator_name() {
    var unit = parseCompilationUnit('class A { operator/() : super(); }',
        errors: [
          expectedError(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 10, 8)
        ]);
    var classDeclaration = unit.declarations[0] as ClassDeclaration;
    var constructor = classDeclaration.members[0] as ConstructorDeclaration;
    var invocation = constructor.initializers[0] as SuperConstructorInvocation;
    expect(invocation.argumentList.arguments, hasLength(0));
  }

  void test_parseField_const_late() {
    createParser('const late T f = 0;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.CONFLICTING_MODIFIERS, 6, 4),
    ]);
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isTrue);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseField_final_late() {
    createParser('final late T f;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    assertErrors(errors: [
      expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 6, 4),
    ]);
    expect(member, isNotNull);
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isTrue);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseField_late() {
    createParser('late T f;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseField_late_const() {
    createParser('late const T f = 0;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.CONFLICTING_MODIFIERS, 5, 5),
    ]);
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isTrue);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseField_late_final() {
    createParser('late final T f;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isTrue);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseField_late_var() {
    createParser('late var f;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseField_var_late() {
    createParser('var late f;', featureSet: nonNullable);
    ClassMember member = parser.parseClassMember('C');
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 4, 4),
    ]);
    expect(member, isFieldDeclaration);
    FieldDeclaration field = member;
    expect(field.covariantKeyword, isNull);
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    expect(list.keyword, isNotNull);
    expect(list.isConst, isFalse);
    expect(list.isFinal, isFalse);
    expect(list.isLate, isTrue);
    expect(list.lateKeyword, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }
}

/// Tests of the fasta parser based on [ExpressionParserTestMixin].
@reflectiveTest
class CollectionLiteralParserTest extends FastaParserTestCase {
  Expression parseCollectionLiteral(String source,
      {List<ErrorCode> codes,
      List<ExpectedError> errors,
      int expectedEndOffset,
      bool inAsync = false}) {
    return parseExpression(source,
        codes: codes,
        errors: errors,
        expectedEndOffset: expectedEndOffset,
        inAsync: inAsync,
        featureSet: FeatureSet.forTesting(
            sdkVersion: '2.0.0',
            additionalFeatures: [
              Feature.spread_collections,
              Feature.control_flow_collections
            ]));
  }

  void test_listLiteral_for() {
    ListLiteral list = parseCollectionLiteral(
      '[1, await for (var x in list) 2]',
      inAsync: true,
    );
    expect(list.elements, hasLength(2));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);

    ForElement second = list.elements[1];
    expect(second.awaitKeyword, isNotNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    ForEachPartsWithDeclaration forLoopParts = second.forLoopParts;
    DeclaredIdentifier forLoopVar = forLoopParts.loopVariable;
    expect(forLoopVar.identifier.name, 'x');
    expect(forLoopParts.inKeyword, isNotNull);
    SimpleIdentifier iterable = forLoopParts.iterable;
    expect(iterable.name, 'list');
  }

  void test_listLiteral_forIf() {
    ListLiteral list = parseCollectionLiteral(
      '[1, await for (var x in list) if (c) 2]',
      inAsync: true,
    );
    expect(list.elements, hasLength(2));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);

    ForElement second = list.elements[1];
    expect(second.awaitKeyword, isNotNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    ForEachPartsWithDeclaration forLoopParts = second.forLoopParts;
    DeclaredIdentifier forLoopVar = forLoopParts.loopVariable;
    expect(forLoopVar.identifier.name, 'x');
    expect(forLoopParts.inKeyword, isNotNull);
    SimpleIdentifier iterable = forLoopParts.iterable;
    expect(iterable.name, 'list');

    IfElement body = second.body;
    SimpleIdentifier condition = body.condition;
    expect(condition.name, 'c');
    IntegerLiteral thenElement = body.thenElement;
    expect(thenElement.value, 2);
  }

  void test_listLiteral_forSpread() {
    ListLiteral list =
        parseCollectionLiteral('[1, for (int x = 0; x < 10; ++x) ...[2]]');
    expect(list.elements, hasLength(2));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);

    ForElement second = list.elements[1];
    expect(second.awaitKeyword, isNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    ForPartsWithDeclarations forLoopParts = second.forLoopParts;
    VariableDeclaration forLoopVar = forLoopParts.variables.variables[0];
    expect(forLoopVar.name.name, 'x');
    BinaryExpression condition = forLoopParts.condition;
    IntegerLiteral rightOperand = condition.rightOperand;
    expect(rightOperand.value, 10);
    PrefixExpression updater = forLoopParts.updaters[0];
    SimpleIdentifier updaterOperand = updater.operand;
    expect(updaterOperand.name, 'x');
  }

  void test_listLiteral_if() {
    ListLiteral list = parseCollectionLiteral('[1, if (true) 2]');
    expect(list.elements, hasLength(2));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);

    IfElement second = list.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    IntegerLiteral thenElement = second.thenElement;
    expect(thenElement.value, 2);
    expect(second.elseElement, isNull);
  }

  void test_listLiteral_ifElse() {
    ListLiteral list = parseCollectionLiteral('[1, if (true) 2 else 5]');
    expect(list.elements, hasLength(2));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);

    IfElement second = list.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    IntegerLiteral thenElement = second.thenElement;
    expect(thenElement.value, 2);
    IntegerLiteral elseElement = second.elseElement;
    expect(elseElement.value, 5);
  }

  void test_listLiteral_ifElseFor() {
    ListLiteral list =
        parseCollectionLiteral('[1, if (true) 2 else for (a in b) 5]');
    expect(list.elements, hasLength(2));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);

    IfElement second = list.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    IntegerLiteral thenElement = second.thenElement;
    expect(thenElement.value, 2);

    ForElement elseElement = second.elseElement;
    ForEachPartsWithIdentifier forLoopParts = elseElement.forLoopParts;
    expect(forLoopParts.identifier.name, 'a');

    IntegerLiteral forValue = elseElement.body;
    expect(forValue.value, 5);
  }

  void test_listLiteral_ifElseSpread() {
    ListLiteral list =
        parseCollectionLiteral('[1, if (true) ...[2] else ...?[5]]');
    expect(list.elements, hasLength(2));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);

    IfElement second = list.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    SpreadElement thenElement = second.thenElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    SpreadElement elseElement = second.elseElement;
    expect(elseElement.spreadOperator.lexeme, '...?');
  }

  void test_listLiteral_ifFor() {
    ListLiteral list = parseCollectionLiteral('[1, if (true) for (a in b) 2]');
    expect(list.elements, hasLength(2));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);

    IfElement second = list.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);

    ForElement thenElement = second.thenElement;
    ForEachPartsWithIdentifier forLoopParts = thenElement.forLoopParts;
    expect(forLoopParts.identifier.name, 'a');

    IntegerLiteral forValue = thenElement.body;
    expect(forValue.value, 2);
    expect(second.elseElement, isNull);
  }

  void test_listLiteral_ifSpread() {
    ListLiteral list = parseCollectionLiteral('[1, if (true) ...[2]]');
    expect(list.elements, hasLength(2));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);

    IfElement second = list.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    SpreadElement thenElement = second.thenElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    expect(second.elseElement, isNull);
  }

  void test_listLiteral_spread() {
    ListLiteral list = parseCollectionLiteral('[1, ...[2]]');
    expect(list.elements, hasLength(2));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);

    SpreadElement element = list.elements[1];
    expect(element.spreadOperator.lexeme, '...');
    ListLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_listLiteral_spreadQ() {
    ListLiteral list = parseCollectionLiteral('[1, ...?[2]]');
    expect(list.elements, hasLength(2));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);

    SpreadElement element = list.elements[1];
    expect(element.spreadOperator.lexeme, '...?');
    ListLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_for() {
    SetOrMapLiteral map = parseCollectionLiteral(
        '{1:7, await for (y in list) 2:3}',
        inAsync: true);
    expect(map.elements, hasLength(2));
    MapLiteralEntry first = map.elements[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 7);

    ForElement second = map.elements[1];
    expect(second.awaitKeyword, isNotNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    ForEachPartsWithIdentifier forLoopParts = second.forLoopParts;
    SimpleIdentifier forLoopVar = forLoopParts.identifier;
    expect(forLoopVar.name, 'y');
    expect(forLoopParts.inKeyword, isNotNull);
    SimpleIdentifier iterable = forLoopParts.iterable;
    expect(iterable.name, 'list');
  }

  void test_mapLiteral_forIf() {
    SetOrMapLiteral map = parseCollectionLiteral(
        '{1:7, await for (y in list) if (c) 2:3}',
        inAsync: true);
    expect(map.elements, hasLength(2));
    MapLiteralEntry first = map.elements[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 7);

    ForElement second = map.elements[1];
    expect(second.awaitKeyword, isNotNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    ForEachPartsWithIdentifier forLoopParts = second.forLoopParts;
    SimpleIdentifier forLoopVar = forLoopParts.identifier;
    expect(forLoopVar.name, 'y');
    expect(forLoopParts.inKeyword, isNotNull);
    SimpleIdentifier iterable = forLoopParts.iterable;
    expect(iterable.name, 'list');

    IfElement body = second.body;
    SimpleIdentifier condition = body.condition;
    expect(condition.name, 'c');
    MapLiteralEntry thenElement = body.thenElement;
    IntegerLiteral thenValue = thenElement.value;
    expect(thenValue.value, 3);
  }

  void test_mapLiteral_forSpread() {
    SetOrMapLiteral map =
        parseCollectionLiteral('{1:7, for (x = 0; x < 10; ++x) ...{2:3}}');
    expect(map.elements, hasLength(2));
    MapLiteralEntry first = map.elements[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 7);

    ForElement second = map.elements[1];
    expect(second.awaitKeyword, isNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    ForPartsWithExpression forLoopParts = second.forLoopParts;
    AssignmentExpression forLoopInit = forLoopParts.initialization;
    SimpleIdentifier forLoopVar = forLoopInit.leftHandSide;
    expect(forLoopVar.name, 'x');
    BinaryExpression condition = forLoopParts.condition;
    IntegerLiteral rightOperand = condition.rightOperand;
    expect(rightOperand.value, 10);
    PrefixExpression updater = forLoopParts.updaters[0];
    SimpleIdentifier updaterOperand = updater.operand;
    expect(updaterOperand.name, 'x');
  }

  void test_mapLiteral_if() {
    SetOrMapLiteral map = parseCollectionLiteral('{1:1, if (true) 2:4}');
    expect(map.elements, hasLength(2));
    MapLiteralEntry first = map.elements[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 1);

    IfElement second = map.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    MapLiteralEntry thenElement = second.thenElement;
    IntegerLiteral thenElementValue = thenElement.value;
    expect(thenElementValue.value, 4);
    expect(second.elseElement, isNull);
  }

  void test_mapLiteral_ifElse() {
    SetOrMapLiteral map =
        parseCollectionLiteral('{1:1, if (true) 2:4 else 5:6}');
    expect(map.elements, hasLength(2));
    MapLiteralEntry first = map.elements[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 1);

    IfElement second = map.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    MapLiteralEntry thenElement = second.thenElement;
    IntegerLiteral thenElementValue = thenElement.value;
    expect(thenElementValue.value, 4);
    MapLiteralEntry elseElement = second.elseElement;
    IntegerLiteral elseElementValue = elseElement.value;
    expect(elseElementValue.value, 6);
  }

  void test_mapLiteral_ifElseFor() {
    SetOrMapLiteral map =
        parseCollectionLiteral('{1:1, if (true) 2:4 else for (c in d) 5:6}');
    expect(map.elements, hasLength(2));
    MapLiteralEntry first = map.elements[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 1);

    IfElement second = map.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    MapLiteralEntry thenElement = second.thenElement;
    IntegerLiteral thenElementValue = thenElement.value;
    expect(thenElementValue.value, 4);

    ForElement elseElement = second.elseElement;
    ForEachPartsWithIdentifier forLoopParts = elseElement.forLoopParts;
    expect(forLoopParts.identifier.name, 'c');

    MapLiteralEntry body = elseElement.body;
    IntegerLiteral bodyValue = body.value;
    expect(bodyValue.value, 6);
  }

  void test_mapLiteral_ifElseSpread() {
    SetOrMapLiteral map =
        parseCollectionLiteral('{1:7, if (true) ...{2:4} else ...?{5:6}}');
    expect(map.elements, hasLength(2));
    MapLiteralEntry first = map.elements[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 7);

    IfElement second = map.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    SpreadElement thenElement = second.thenElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    SpreadElement elseElement = second.elseElement;
    expect(elseElement.spreadOperator.lexeme, '...?');
    SetOrMapLiteral elseElementExpression = elseElement.expression;
    expect(elseElementExpression.elements, hasLength(1));
    MapLiteralEntry entry = elseElementExpression.elements[0];
    IntegerLiteral entryValue = entry.value;
    expect(entryValue.value, 6);
  }

  void test_mapLiteral_ifFor() {
    SetOrMapLiteral map =
        parseCollectionLiteral('{1:1, if (true) for (a in b) 2:4}');
    expect(map.elements, hasLength(2));
    MapLiteralEntry first = map.elements[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 1);

    IfElement second = map.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);

    ForElement thenElement = second.thenElement;
    ForEachPartsWithIdentifier forLoopParts = thenElement.forLoopParts;
    expect(forLoopParts.identifier.name, 'a');

    MapLiteralEntry body = thenElement.body;
    IntegerLiteral thenElementValue = body.value;
    expect(thenElementValue.value, 4);
    expect(second.elseElement, isNull);
  }

  void test_mapLiteral_ifSpread() {
    SetOrMapLiteral map = parseCollectionLiteral('{1:1, if (true) ...{2:4}}');
    expect(map.elements, hasLength(2));
    MapLiteralEntry first = map.elements[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 1);

    IfElement second = map.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    SpreadElement thenElement = second.thenElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    expect(second.elseElement, isNull);
  }

  void test_mapLiteral_spread() {
    SetOrMapLiteral map = parseCollectionLiteral('{1: 2, ...{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(2));

    SpreadElement element = map.elements[1];
    expect(element.spreadOperator.lexeme, '...');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spread2_typed() {
    SetOrMapLiteral map = parseCollectionLiteral('<int, int>{1: 2, ...{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(2));

    SpreadElement element = map.elements[1];
    expect(element.spreadOperator.lexeme, '...');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spread_typed() {
    SetOrMapLiteral map = parseCollectionLiteral('<int, int>{...{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(1));

    SpreadElement element = map.elements[0];
    expect(element.spreadOperator.lexeme, '...');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spreadQ() {
    SetOrMapLiteral map = parseCollectionLiteral('{1: 2, ...?{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(2));

    SpreadElement element = map.elements[1];
    expect(element.spreadOperator.lexeme, '...?');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spreadQ2_typed() {
    SetOrMapLiteral map =
        parseCollectionLiteral('<int, int>{1: 2, ...?{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(2));

    SpreadElement element = map.elements[1];
    expect(element.spreadOperator.lexeme, '...?');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spreadQ_typed() {
    SetOrMapLiteral map = parseCollectionLiteral('<int, int>{...?{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(1));

    SpreadElement element = map.elements[0];
    expect(element.spreadOperator.lexeme, '...?');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setLiteral_if() {
    SetOrMapLiteral setLiteral = parseCollectionLiteral('{1, if (true) 2}');
    expect(setLiteral.elements, hasLength(2));
    IntegerLiteral first = setLiteral.elements[0];
    expect(first.value, 1);

    IfElement second = setLiteral.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    IntegerLiteral thenElement = second.thenElement;
    expect(thenElement.value, 2);
    expect(second.elseElement, isNull);
  }

  void test_setLiteral_ifElse() {
    SetOrMapLiteral setLiteral =
        parseCollectionLiteral('{1, if (true) 2 else 5}');
    expect(setLiteral.elements, hasLength(2));
    IntegerLiteral first = setLiteral.elements[0];
    expect(first.value, 1);

    IfElement second = setLiteral.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    IntegerLiteral thenElement = second.thenElement;
    expect(thenElement.value, 2);
    IntegerLiteral elseElement = second.elseElement;
    expect(elseElement.value, 5);
  }

  void test_setLiteral_ifElseSpread() {
    SetOrMapLiteral setLiteral =
        parseCollectionLiteral('{1, if (true) ...{2} else ...?[5]}');
    expect(setLiteral.elements, hasLength(2));
    IntegerLiteral first = setLiteral.elements[0];
    expect(first.value, 1);

    IfElement second = setLiteral.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    SpreadElement thenElement = second.thenElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    SetOrMapLiteral theExpression = thenElement.expression;
    expect(theExpression.elements, hasLength(1));
    SpreadElement elseElement = second.elseElement;
    expect(elseElement.spreadOperator.lexeme, '...?');
    ListLiteral elseExpression = elseElement.expression;
    expect(elseExpression.elements, hasLength(1));
  }

  void test_setLiteral_ifSpread() {
    SetOrMapLiteral setLiteral =
        parseCollectionLiteral('{1, if (true) ...[2]}');
    expect(setLiteral.elements, hasLength(2));
    IntegerLiteral first = setLiteral.elements[0];
    expect(first.value, 1);

    IfElement second = setLiteral.elements[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    SpreadElement thenElement = second.thenElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    expect(second.elseElement, isNull);
  }

  void test_setLiteral_spread2() {
    SetOrMapLiteral set = parseCollectionLiteral('{3, ...[4]}');
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements, hasLength(2));
    IntegerLiteral value = set.elements[0];
    expect(value.value, 3);

    SpreadElement element = set.elements[1];
    expect(element.spreadOperator.lexeme, '...');
    ListLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setLiteral_spread2Q() {
    SetOrMapLiteral set = parseCollectionLiteral('{3, ...?[4]}');
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements, hasLength(2));
    IntegerLiteral value = set.elements[0];
    expect(value.value, 3);

    SpreadElement element = set.elements[1];
    expect(element.spreadOperator.lexeme, '...?');
    ListLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setLiteral_spread_typed() {
    SetOrMapLiteral set = parseCollectionLiteral('<int>{...[3]}');
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNotNull);
    expect(set.elements, hasLength(1));

    SpreadElement element = set.elements[0];
    expect(element.spreadOperator.lexeme, '...');
    ListLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setLiteral_spreadQ_typed() {
    SetOrMapLiteral set = parseCollectionLiteral('<int>{...?[3]}');
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNotNull);
    expect(set.elements, hasLength(1));

    SpreadElement element = set.elements[0];
    expect(element.spreadOperator.lexeme, '...?');
    ListLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setOrMapLiteral_spread() {
    SetOrMapLiteral map = parseCollectionLiteral('{...{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(1));

    SpreadElement element = map.elements[0];
    expect(element.spreadOperator.lexeme, '...');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setOrMapLiteral_spreadQ() {
    SetOrMapLiteral map = parseCollectionLiteral('{...?{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(1));

    SpreadElement element = map.elements[0];
    expect(element.spreadOperator.lexeme, '...?');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements, hasLength(1));
  }
}

/// Tests of the fasta parser based on [ComplexParserTestMixin].
@reflectiveTest
class ComplexParserTest_Fasta extends FastaParserTestCase
    with ComplexParserTestMixin {
  void test_conditionalExpression_precedence_nullableType_as2() {
    ExpressionStatement statement = parseStatement('x as bool? ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    AsExpression asExpression = expression.condition;
    TypeName type = asExpression.type;
    expect(type.question.lexeme, '?');
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
    assertErrors(
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 9, 1)]);
  }

  void test_conditionalExpression_precedence_nullableType_as3() {
    ExpressionStatement statement =
        parseStatement('(x as bool?) ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    ParenthesizedExpression condition = expression.condition;
    AsExpression asExpression = condition.expression;
    TypeName type = asExpression.type;
    expect(type.question.lexeme, '?');
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
    assertErrors(
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 10, 1)]);
  }

  void test_conditionalExpression_precedence_nullableType_is2() {
    ExpressionStatement statement =
        parseStatement('x is String? ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    IsExpression isExpression = expression.condition;
    TypeName type = isExpression.type;
    expect(type.question.lexeme, '?');
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
    assertErrors(
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 11, 1)]);
  }

  void test_conditionalExpression_precedence_nullableType_is3() {
    ExpressionStatement statement =
        parseStatement('(x is String?) ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    ParenthesizedExpression condition = expression.condition;
    IsExpression isExpression = condition.expression;
    TypeName type = isExpression.type;
    expect(type.question.lexeme, '?');
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
    assertErrors(
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 12, 1)]);
  }
}

/// Tests of the fasta parser based on [ErrorParserTest].
@reflectiveTest
class ErrorParserTest_Fasta extends FastaParserTestCase
    with ErrorParserTestMixin {
  void test_await_missing_async2_issue36048() {
    parseCompilationUnit('''
main() { // missing async
  await foo.bar();
}
''', errors: [
      expectedError(CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, 28, 5)
    ]);
  }

  void test_await_missing_async3_issue36048() {
    parseCompilationUnit('''
main() { // missing async
  (await foo);
}
''', errors: [
      expectedError(CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, 29, 5)
    ]);
  }

  void test_await_missing_async4_issue36048() {
    parseCompilationUnit('''
main() { // missing async
  [await foo];
}
''', errors: [
      expectedError(CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, 29, 5)
    ]);
  }

  void test_await_missing_async_issue36048() {
    parseCompilationUnit('''
main() { // missing async
  await foo();
}
''', errors: [
      expectedError(CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, 28, 5)
    ]);
  }

  void test_constructor_super_cascade_synthetic() {
    // https://github.com/dart-lang/sdk/issues/37110
    parseCompilationUnit('class B extends A { B(): super.. {} }', errors: [
      expectedError(ParserErrorCode.INVALID_SUPER_IN_INITIALIZER, 25, 5),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 30, 2),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 33, 1),
    ]);
  }

  void test_constructor_super_field() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    parseCompilationUnit('class B extends A { B(): super().foo {} }', errors: [
      expectedError(ParserErrorCode.INVALID_SUPER_IN_INITIALIZER, 25, 5),
    ]);
  }

  void test_constructor_super_method() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    parseCompilationUnit('class B extends A { B(): super().foo() {} }',
        errors: [
          expectedError(ParserErrorCode.INVALID_SUPER_IN_INITIALIZER, 25, 5),
        ]);
  }

  void test_constructor_super_named_method() {
    // https://github.com/dart-lang/sdk/issues/37600
    parseCompilationUnit('class B extends A { B(): super.c().create() {} }',
        errors: [
          expectedError(ParserErrorCode.INVALID_SUPER_IN_INITIALIZER, 25, 5),
        ]);
  }

  void test_constructor_super_named_method_method() {
    // https://github.com/dart-lang/sdk/issues/37600
    parseCompilationUnit('class B extends A { B(): super.c().create().x() {} }',
        errors: [
          expectedError(ParserErrorCode.INVALID_SUPER_IN_INITIALIZER, 25, 5),
        ]);
  }

  void test_constructor_this_cascade_synthetic() {
    // https://github.com/dart-lang/sdk/issues/37110
    parseCompilationUnit('class B extends A { B(): this.. {} }', errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 25, 4),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 29, 2),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 32, 1),
    ]);
  }

  void test_constructor_this_field() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    parseCompilationUnit('class B extends A { B(): this().foo; }', errors: [
      expectedError(ParserErrorCode.INVALID_THIS_IN_INITIALIZER, 25, 4),
    ]);
  }

  void test_constructor_this_method() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    parseCompilationUnit('class B extends A { B(): this().foo(); }', errors: [
      expectedError(ParserErrorCode.INVALID_THIS_IN_INITIALIZER, 25, 4),
    ]);
  }

  void test_constructor_this_named_method() {
    // https://github.com/dart-lang/sdk/issues/37600
    parseCompilationUnit('class B extends A { B(): super.c().create() {} }',
        errors: [
          expectedError(ParserErrorCode.INVALID_SUPER_IN_INITIALIZER, 25, 5),
        ]);
  }

  void test_constructor_this_named_method_field() {
    // https://github.com/dart-lang/sdk/issues/37600
    parseCompilationUnit('class B extends A { B(): super.c().create().x {} }',
        errors: [
          expectedError(ParserErrorCode.INVALID_SUPER_IN_INITIALIZER, 25, 5),
        ]);
  }

  @override
  void test_expectedListOrMapLiteral() {
    // The fasta parser returns an 'IntegerLiteralImpl' when parsing '1'.
    // This test is not expected to ever pass.
    //super.test_expectedListOrMapLiteral();
  }

  @override
  void test_expectedStringLiteral() {
    // The fasta parser returns an 'IntegerLiteralImpl' when parsing '1'.
    // This test is not expected to ever pass.
    //super.test_expectedStringLiteral();
  }

  void test_factory_issue_36400() {
    parseCompilationUnit('class T { T factory T() { return null; } }',
        errors: [expectedError(ParserErrorCode.TYPE_BEFORE_FACTORY, 10, 1)]);
  }

  void test_getterNativeWithBody() {
    createParser('String get m native "str" => 0;');
    parser.parseClassMember('C') as MethodDeclaration;
    if (!allowNativeClause) {
      assertErrorsWithCodes([
        ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION,
        ParserErrorCode.EXTERNAL_METHOD_WITH_BODY,
      ]);
    } else {
      assertErrorsWithCodes([
        ParserErrorCode.EXTERNAL_METHOD_WITH_BODY,
      ]);
    }
  }

  void test_invalidOperatorAfterSuper_constructorInitializer2() {
    parseCompilationUnit('class C { C() : super?.namedConstructor(); }',
        errors: [
          expectedError(
              ParserErrorCode.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER,
              21,
              2)
        ]);
  }

  void test_missing_closing_bracket_issue37528() {
    final code = '\${foo';
    createParser(code);
    final result = fasta.scanString(code);
    expect(result.hasErrors, isTrue);
    var token = _parserProxy.fastaParser.syntheticPreviousToken(result.tokens);
    try {
      _parserProxy.fastaParser.parseExpression(token);
      // TODO(danrubel): Replace this test once root cause is found
      fail('exception expected');
    } catch (e) {
      var msg = e.toString();
      expect(msg.contains('test_missing_closing_bracket_issue37528'), isTrue);
    }
  }

  void test_partialNamedConstructor() {
    parseCompilationUnit('class C { C. }', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 13, 1),
      expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 10, 1),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 13, 1),
    ]);
  }

  void test_staticOperatorNamedMethod() {
    // operator can be used as a method name
    parseCompilationUnit('class C { static operator(x) => x; }');
  }

  void test_yieldAsLabel() {
    // yield can be used as a label
    parseCompilationUnit('main() { yield: break yield; }');
  }
}

/// Tests of the fasta parser based on [ExpressionParserTestMixin].
@reflectiveTest
class ExpressionParserTest_Fasta extends FastaParserTestCase
    with ExpressionParserTestMixin {
  final beforeUiAsCode = FeatureSet.forTesting(sdkVersion: '2.2.0');

  void test_binaryExpression_allOperators() {
    // https://github.com/dart-lang/sdk/issues/36255
    for (TokenType type in TokenType.all) {
      if (type.precedence > 0) {
        var source = 'a ${type.lexeme} b';
        try {
          parseExpression(source);
        } on TestFailure {
          // Ensure that there are no infinite loops or exceptions thrown
          // by the parser. Test failures are fine.
        }
      }
    }
  }

  void test_invalidExpression_37706() {
    // https://github.com/dart-lang/sdk/issues/37706
    parseExpression('<b?c>()', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 1, 1),
      expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 7, 0),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 7, 0),
    ]);
  }

  void test_listLiteral_invalid_assert() {
    // https://github.com/dart-lang/sdk/issues/37674
    parseExpression('n=<.["\$assert', errors: [
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 3, 1),
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 4, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 7, 6),
      expectedError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 12, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 13, 1),
    ]);
  }

  void test_listLiteral_invalidElement_37697() {
    // https://github.com/dart-lang/sdk/issues/37674
    parseExpression('[<y.<z>(){}]', errors: [
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 4, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 1),
    ]);
  }

  void test_listLiteral_spread_disabled() {
    ListLiteral list =
        parseExpression('[1, ...[2]]', featureSet: beforeUiAsCode, errors: [
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 4, 3),
    ]);
    expect(list.elements, hasLength(1));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);
  }

  void test_listLiteral_spreadQ_disabled() {
    ListLiteral list =
        parseExpression('[1, ...?[2]]', featureSet: beforeUiAsCode, errors: [
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 4, 4),
    ]);
    expect(list.elements, hasLength(1));
    IntegerLiteral first = list.elements[0];
    expect(first.value, 1);
  }

  void test_lt_dot_bracket_quote() {
    // https://github.com/dart-lang/sdk/issues/37674
    ListLiteral list = parseExpression('<.["', errors: [
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 1, 1),
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 2, 1),
      expectedError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 3, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 4, 1),
    ]);
    expect(list.elements, hasLength(1));
    StringLiteral first = list.elements[0];
    expect(first.length, 1);
  }

  void test_lt_dot_listLiteral() {
    // https://github.com/dart-lang/sdk/issues/37674
    ListLiteral list = parseExpression('<.[]', errors: [
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 1, 1),
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 2, 2),
    ]);
    expect(list.elements, hasLength(0));
  }

  void test_mapLiteral() {
    SetOrMapLiteral map = parseExpression('{3: 6}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(1));
    MapLiteralEntry entry = map.elements[0];
    IntegerLiteral key = entry.key;
    expect(key.value, 3);
    IntegerLiteral value = entry.value;
    expect(value.value, 6);
  }

  void test_mapLiteral_const() {
    SetOrMapLiteral map = parseExpression('const {3: 6}');
    expect(map.constKeyword, isNotNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(1));
    MapLiteralEntry entry = map.elements[0];
    IntegerLiteral key = entry.key;
    expect(key.value, 3);
    IntegerLiteral value = entry.value;
    expect(value.value, 6);
  }

  void test_mapLiteral_invalid_set_entry_uiAsCodeDisabled() {
    SetOrMapLiteral map =
        parseExpression('<int, int>{1}', featureSet: beforeUiAsCode, errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 12, 1),
    ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(1));
  }

  @failingTest
  void test_mapLiteral_invalid_too_many_type_arguments1() {
    SetOrMapLiteral map = parseExpression('<int, int, int>{}', errors: [
      // TODO(danrubel): Currently the resolver reports invalid number of
      // type arguments, but the parser could report this.
      expectedError(
          /* ParserErrorCode.EXPECTED_ONE_OR_TWO_TYPE_VARIABLES */
          ParserErrorCode.EXPECTED_TOKEN,
          11,
          3),
    ]);
    expect(map.constKeyword, isNull);
    expect(map.elements, hasLength(0));
  }

  @failingTest
  void test_mapLiteral_invalid_too_many_type_arguments2() {
    SetOrMapLiteral map = parseExpression('<int, int, int>{1}', errors: [
      // TODO(danrubel): Currently the resolver reports invalid number of
      // type arguments, but the parser could report this.
      expectedError(
          /* ParserErrorCode.EXPECTED_ONE_OR_TWO_TYPE_VARIABLES */
          ParserErrorCode.EXPECTED_TOKEN,
          11,
          3),
    ]);
    expect(map.constKeyword, isNull);
    expect(map.elements, hasLength(0));
  }

  void test_mapLiteral_spread2_typed_disabled() {
    SetOrMapLiteral map = parseExpression('<int, int>{1: 2, ...{3: 4}}',
        featureSet: beforeUiAsCode,
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 17, 3),
        ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(1));
  }

  void test_mapLiteral_spread_disabled() {
    SetOrMapLiteral map = parseExpression('{1: 2, ...{3: 4}}',
        featureSet: beforeUiAsCode,
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 7, 3),
        ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(1));
  }

  void test_mapLiteral_spread_typed_disabled() {
    SetOrMapLiteral map = parseExpression('<int, int>{...{3: 4}}',
        featureSet: beforeUiAsCode,
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 11, 3),
        ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(0));
  }

  void test_mapLiteral_spreadQ2_typed_disabled() {
    SetOrMapLiteral map = parseExpression('<int, int>{1: 2, ...?{3: 4}}',
        featureSet: beforeUiAsCode,
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 17, 4),
        ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(1));
  }

  void test_mapLiteral_spreadQ_disabled() {
    SetOrMapLiteral map = parseExpression('{1: 2, ...?{3: 4}}',
        featureSet: beforeUiAsCode,
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 7, 4),
        ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(1));
  }

  void test_mapLiteral_spreadQ_typed_disabled() {
    SetOrMapLiteral map = parseExpression('<int, int>{...?{3: 4}}',
        featureSet: beforeUiAsCode,
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 11, 4),
        ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(0));
  }

  void test_parseConstructorInitializer_functionExpression() {
    // https://github.com/dart-lang/sdk/issues/37414
    parseCompilationUnit('class C { C.n() : this()(); }', errors: [
      expectedError(ParserErrorCode.INVALID_INITIALIZER, 18, 8),
    ]);
  }

  void test_parseStringLiteral_interpolated_void() {
    Expression expression = parseStringLiteral(r"'<html>$void</html>'");
    expect(expression, isNotNull);
    assertErrors(
        errors: [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 4)]);
    expect(expression, isStringInterpolation);
    StringInterpolation literal = expression;
    NodeList<InterpolationElement> elements = literal.elements;
    expect(elements, hasLength(3));
    expect(elements[0] is InterpolationString, isTrue);
    expect(elements[1] is InterpolationExpression, isTrue);
    expect(elements[2] is InterpolationString, isTrue);
    expect((elements[1] as InterpolationExpression).leftBracket.lexeme, '\$');
    expect((elements[1] as InterpolationExpression).rightBracket, isNull);
  }

  @override
  @failingTest
  void test_parseUnaryExpression_decrement_super() {
    // TODO(danrubel) Reports a different error and different token stream.
    // Expected: TokenType:<MINUS>
    //   Actual: TokenType:<MINUS_MINUS>
    super.test_parseUnaryExpression_decrement_super();
  }

  @override
  @failingTest
  void test_parseUnaryExpression_decrement_super_withComment() {
    // TODO(danrubel) Reports a different error and different token stream.
    // Expected: TokenType:<MINUS>
    //   Actual: TokenType:<MINUS_MINUS>
    super.test_parseUnaryExpression_decrement_super_withComment();
  }

  void test_setLiteral() {
    SetOrMapLiteral set = parseExpression('{3}');
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements, hasLength(1));
    IntegerLiteral value = set.elements[0];
    expect(value.value, 3);
  }

  void test_setLiteral_const() {
    SetOrMapLiteral set = parseExpression('const {3, 6}');
    expect(set.constKeyword, isNotNull);
    expect(set.typeArguments, isNull);
    expect(set.elements, hasLength(2));
    IntegerLiteral value1 = set.elements[0];
    expect(value1.value, 3);
    IntegerLiteral value2 = set.elements[1];
    expect(value2.value, 6);
  }

  void test_setLiteral_const_typed() {
    SetOrMapLiteral set = parseExpression('const <int>{3}');
    expect(set.constKeyword, isNotNull);
    expect(set.typeArguments.arguments, hasLength(1));
    NamedType typeArg = set.typeArguments.arguments[0];
    expect(typeArg.name.name, 'int');
    expect(set.elements.length, 1);
    IntegerLiteral value = set.elements[0];
    expect(value.value, 3);
  }

  void test_setLiteral_invalid_map_entry_beforeUiAsCode() {
    SetOrMapLiteral set =
        parseExpression('<int>{1: 1}', featureSet: beforeUiAsCode, errors: [
      expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 7, 1),
    ]);
    expect(set.constKeyword, isNull);
    expect(set.typeArguments.arguments, hasLength(1));
    NamedType typeArg = set.typeArguments.arguments[0];
    expect(typeArg.name.name, 'int');
    expect(set.elements.length, 1);
  }

  void test_setLiteral_nested_typeArgument() {
    SetOrMapLiteral set = parseExpression('<Set<int>>{{3}}');
    expect(set.constKeyword, isNull);
    expect(set.typeArguments.arguments, hasLength(1));
    NamedType typeArg1 = set.typeArguments.arguments[0];
    expect(typeArg1.name.name, 'Set');
    expect(typeArg1.typeArguments.arguments, hasLength(1));
    NamedType typeArg2 = typeArg1.typeArguments.arguments[0];
    expect(typeArg2.name.name, 'int');
    expect(set.elements.length, 1);
    SetOrMapLiteral intSet = set.elements[0];
    expect(intSet.elements, hasLength(1));
    IntegerLiteral value = intSet.elements[0];
    expect(value.value, 3);
  }

  void test_setLiteral_spread2_disabled() {
    SetOrMapLiteral set = parseExpression('{3, ...[4]}',
        featureSet: beforeUiAsCode,
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 4, 3)]);
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements, hasLength(1));
    IntegerLiteral value = set.elements[0];
    expect(value.value, 3);
  }

  void test_setLiteral_spread2Q_disabled() {
    SetOrMapLiteral set = parseExpression('{3, ...?[4]}',
        featureSet: beforeUiAsCode,
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 4, 4)]);
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements, hasLength(1));
    IntegerLiteral value = set.elements[0];
    expect(value.value, 3);
  }

  void test_setLiteral_spread_typed_disabled() {
    SetOrMapLiteral set = parseExpression('<int>{...[3]}',
        featureSet: beforeUiAsCode,
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 6, 3)]);
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNotNull);
    expect(set.elements, hasLength(0));
  }

  void test_setLiteral_spreadQ_typed_disabled() {
    SetOrMapLiteral set = parseExpression('<int>{...?[3]}',
        featureSet: beforeUiAsCode,
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 6, 4)]);
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNotNull);
    expect(set.elements, hasLength(0));
  }

  void test_setLiteral_typed() {
    SetOrMapLiteral set = parseExpression('<int>{3}');
    expect(set.constKeyword, isNull);
    expect(set.typeArguments.arguments, hasLength(1));
    NamedType typeArg = set.typeArguments.arguments[0];
    expect(typeArg.name.name, 'int');
    expect(set.elements.length, 1);
    IntegerLiteral value = set.elements[0];
    expect(value.value, 3);
  }

  void test_setOrMapLiteral_spread_disabled() {
    SetOrMapLiteral map = parseExpression('{...{3: 4}}',
        featureSet: beforeUiAsCode,
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 1, 3)]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(0));
  }

  void test_setOrMapLiteral_spreadQ_disabled() {
    SetOrMapLiteral map = parseExpression('{...?{3: 4}}',
        featureSet: beforeUiAsCode,
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 1, 4)]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(0));
  }
}

@reflectiveTest
class ExtensionMethodsParserTest_Fasta extends FastaParserTestCase {
  void test_complex_extends() {
    var unit = parseCompilationUnit(
        'extension E extends A with B, C implements D { }',
        errors: [
          expectedError(ParserErrorCode.EXPECTED_INSTEAD, 12, 7),
          expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 22, 4),
          expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 28, 1),
          expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 32, 10),
        ]);
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name.name, 'E');
    expect(extension.onKeyword.lexeme, 'extends');
    expect((extension.extendedType as NamedType).name.name, 'A');
    expect(extension.members, hasLength(0));
  }

  void test_complex_implements() {
    var unit = parseCompilationUnit('extension E implements C, D { }', errors: [
      expectedError(ParserErrorCode.EXPECTED_INSTEAD, 12, 10),
      expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 24, 1),
    ]);
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name.name, 'E');
    expect(extension.onKeyword.lexeme, 'implements');
    expect((extension.extendedType as NamedType).name.name, 'C');
    expect(extension.members, hasLength(0));
  }

  void test_complex_type() {
    var unit = parseCompilationUnit('extension E on C<T> { }');
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name.name, 'E');
    expect(extension.onKeyword.lexeme, 'on');
    var namedType = extension.extendedType as NamedType;
    expect(namedType.name.name, 'C');
    expect(namedType.typeArguments.arguments, hasLength(1));
    expect(extension.members, hasLength(0));
  }

  void test_complex_type2() {
    var unit = parseCompilationUnit('extension E<T> on C<T> { }');
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name.name, 'E');
    expect(extension.onKeyword.lexeme, 'on');
    var namedType = extension.extendedType as NamedType;
    expect(namedType.name.name, 'C');
    expect(namedType.typeArguments.arguments, hasLength(1));
    expect(extension.members, hasLength(0));
  }

  void test_complex_type2_no_name() {
    var unit = parseCompilationUnit('extension<T> on C<T> { }');
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name, isNull);
    expect(extension.onKeyword.lexeme, 'on');
    var namedType = extension.extendedType as NamedType;
    expect(namedType.name.name, 'C');
    expect(namedType.typeArguments.arguments, hasLength(1));
    expect(extension.members, hasLength(0));
  }

  void test_constructor_named() {
    var unit = parseCompilationUnit('''
extension E on C {
  E.named();
}
class C {}
''', errors: [
      expectedError(ParserErrorCode.EXTENSION_DECLARES_CONSTRUCTOR, 21, 1),
    ]);
    expect(unit.declarations, hasLength(2));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.members, hasLength(0));
  }

  void test_constructor_unnamed() {
    var unit = parseCompilationUnit('''
extension E on C {
  E();
}
class C {}
''', errors: [
      expectedError(ParserErrorCode.EXTENSION_DECLARES_CONSTRUCTOR, 21, 1),
    ]);
    expect(unit.declarations, hasLength(2));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.members, hasLength(0));
  }

  void test_missing_on() {
    var unit = parseCompilationUnit('extension E', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 1),
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 11, 0),
      expectedError(ParserErrorCode.MISSING_CLASS_BODY, 11, 0),
    ]);
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name.name, 'E');
    expect(extension.onKeyword.lexeme, 'on');
    expect((extension.extendedType as NamedType).name.name, '');
    expect(extension.members, hasLength(0));
  }

  void test_missing_on_withBlock() {
    var unit = parseCompilationUnit('extension E {}', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 1),
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 12, 1),
    ]);
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name.name, 'E');
    expect(extension.onKeyword.lexeme, 'on');
    expect((extension.extendedType as NamedType).name.name, '');
    expect(extension.members, hasLength(0));
  }

  void test_missing_on_withClassAndBlock() {
    var unit = parseCompilationUnit('extension E C {}', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 1),
    ]);
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name.name, 'E');
    expect(extension.onKeyword.lexeme, 'on');
    expect((extension.extendedType as NamedType).name.name, 'C');
    expect(extension.members, hasLength(0));
  }

  void test_parse_toplevel_member_called_late_calling_self() {
    CompilationUnitImpl unit = parseCompilationUnit('void late() { late(); }',
        featureSet: nonNullable);
    FunctionDeclaration method = unit.declarations[0];

    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name.name, 'late');
    expect(method.functionExpression, isNotNull);

    BlockFunctionBody body = method.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;
    expect(invocation.operator, isNull);
    expect(invocation.toSource(), 'late()');
  }

  void test_simple() {
    var unit = parseCompilationUnit('extension E on C { }');
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name.name, 'E');
    expect(extension.onKeyword.lexeme, 'on');
    expect((extension.extendedType as NamedType).name.name, 'C');
    var namedType = extension.extendedType as NamedType;
    expect(namedType.name.name, 'C');
    expect(namedType.typeArguments, isNull);
    expect(extension.members, hasLength(0));
  }

  void test_simple_extends() {
    var unit = parseCompilationUnit('extension E extends C { }', errors: [
      expectedError(ParserErrorCode.EXPECTED_INSTEAD, 12, 7),
    ]);
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name.name, 'E');
    expect(extension.onKeyword.lexeme, 'extends');
    expect((extension.extendedType as NamedType).name.name, 'C');
    expect(extension.members, hasLength(0));
  }

  void test_simple_implements() {
    var unit = parseCompilationUnit('extension E implements C { }', errors: [
      expectedError(ParserErrorCode.EXPECTED_INSTEAD, 12, 10),
    ]);
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name.name, 'E');
    expect(extension.onKeyword.lexeme, 'implements');
    expect((extension.extendedType as NamedType).name.name, 'C');
    expect(extension.members, hasLength(0));
  }

  void test_simple_no_name() {
    var unit = parseCompilationUnit('extension on C { }');
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name, isNull);
    expect(extension.onKeyword.lexeme, 'on');
    expect((extension.extendedType as NamedType).name.name, 'C');
    var namedType = extension.extendedType as NamedType;
    expect(namedType.name.name, 'C');
    expect(namedType.typeArguments, isNull);
    expect(extension.members, hasLength(0));
  }

  void test_simple_not_enabled() {
    parseCompilationUnit('extension E on C { }',
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 0, 9),
          expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 15, 1)
        ],
        featureSet: FeatureSet.forTesting(sdkVersion: '2.3.0'));
  }

  void test_simple_with() {
    var unit = parseCompilationUnit('extension E with C { }', errors: [
      expectedError(ParserErrorCode.EXPECTED_INSTEAD, 12, 4),
    ]);
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name.name, 'E');
    expect(extension.onKeyword.lexeme, 'with');
    expect((extension.extendedType as NamedType).name.name, 'C');
    expect(extension.members, hasLength(0));
  }

  void test_void_type() {
    var unit = parseCompilationUnit('extension E on void { }');
    expect(unit.declarations, hasLength(1));
    var extension = unit.declarations[0] as ExtensionDeclaration;
    expect(extension.name.name, 'E');
    expect(extension.onKeyword.lexeme, 'on');
    expect((extension.extendedType as NamedType).name.name, 'void');
    expect(extension.members, hasLength(0));
  }
}

/// Implementation of [AbstractParserTestCase] specialized for testing the
/// Fasta parser.
class FastaParserTestCase
    with ParserTestHelpers
    implements AbstractParserTestCase {
  static final List<ErrorCode> NO_ERROR_COMPARISON = <ErrorCode>[];

  final controlFlow = FeatureSet.forTesting(
      sdkVersion: '2.0.0',
      additionalFeatures: [Feature.control_flow_collections]);

  final spread = FeatureSet.forTesting(
      sdkVersion: '2.0.0', additionalFeatures: [Feature.spread_collections]);

  final nonNullable = FeatureSet.forTesting(
      sdkVersion: '2.2.2', additionalFeatures: [Feature.non_nullable]);

  final preNonNullable = FeatureSet.forTesting(sdkVersion: '2.2.2');

  ParserProxy _parserProxy;

  analyzer.Token _fastaTokens;

  @override
  bool allowNativeClause = false;

  @override
  set enableOptionalNewAndConst(bool enable) {
    // ignored
  }

  @override
  set enableUriInPartOf(bool value) {
    if (value == false) {
      throw UnimplementedError(
          'URIs in "part of" declarations cannot be disabled in Fasta.');
    }
  }

  @override
  GatheringErrorListener get listener => _parserProxy._errorListener;

  @override
  analyzer.Parser get parser => _parserProxy;

  @override
  bool get usingFastaParser => true;

  void assertErrors({List<ErrorCode> codes, List<ExpectedError> errors}) {
    if (codes != null) {
      if (!identical(codes, NO_ERROR_COMPARISON)) {
        assertErrorsWithCodes(codes);
      }
    } else if (errors != null) {
      listener.assertErrors(errors);
    } else {
      assertNoErrors();
    }
  }

  @override
  void assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes) {
    _parserProxy._errorListener.assertErrorsWithCodes(
        _toFastaGeneratedAnalyzerErrorCodes(expectedErrorCodes));
  }

  @override
  void assertNoErrors() {
    _parserProxy._errorListener.assertNoErrors();
  }

  @override
  void createParser(String content,
      {int expectedEndOffset, FeatureSet featureSet}) {
    featureSet ??= FeatureSet.forTesting();
    var result = scanString(content,
        configuration: featureSet.isEnabled(Feature.non_nullable)
            ? ScannerConfiguration.nonNullable
            : ScannerConfiguration.classic,
        includeComments: true);
    _fastaTokens = result.tokens;
    _parserProxy = ParserProxy(_fastaTokens, featureSet,
        allowNativeClause: allowNativeClause,
        expectedEndOffset: expectedEndOffset);
  }

  @override
  ExpectedError expectedError(ErrorCode code, int offset, int length) =>
      ExpectedError(_toFastaGeneratedAnalyzerErrorCode(code), offset, length);

  @override
  void expectNotNullIfNoErrors(Object result) {
    if (!listener.hasErrors) {
      expect(result, isNotNull);
    }
  }

  @override
  Expression parseAdditiveExpression(String code) {
    return _parseExpression(code);
  }

  Expression parseArgument(String source) {
    createParser(source);
    return _parserProxy.parseArgument();
  }

  @override
  Expression parseAssignableExpression(String code, bool primaryAllowed) {
    return _parseExpression(code);
  }

  @override
  Expression parseAssignableSelector(String code, bool optional,
      {bool allowConditional = true}) {
    if (optional) {
      if (code.isEmpty) {
        return _parseExpression('foo');
      }
      return _parseExpression('(foo)$code');
    }
    return _parseExpression('foo$code');
  }

  @override
  AwaitExpression parseAwaitExpression(String code) {
    var function = _parseExpression('() async => $code') as FunctionExpression;
    return (function.body as ExpressionFunctionBody).expression;
  }

  @override
  Expression parseBitwiseAndExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseBitwiseOrExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseBitwiseXorExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseCascadeSection(String code) {
    var cascadeExpression = _parseExpression('null$code') as CascadeExpression;
    return cascadeExpression.cascadeSections.first;
  }

  @override
  CommentReference parseCommentReference(
      String referenceSource, int sourceOffset) {
    String padding = ' '.padLeft(sourceOffset - 4, 'a');
    String source = '/**$padding[$referenceSource] */ class C { }';
    CompilationUnit unit = parseCompilationUnit(source);
    ClassDeclaration clazz = unit.declarations[0];
    Comment comment = clazz.documentationComment;
    List<CommentReference> references = comment.references;
    if (references.isEmpty) {
      return null;
    } else {
      expect(references, hasLength(1));
      return references[0];
    }
  }

  @override
  CompilationUnit parseCompilationUnit(String content,
      {List<ErrorCode> codes,
      List<ExpectedError> errors,
      FeatureSet featureSet}) {
    GatheringErrorListener listener = GatheringErrorListener(checkRanges: true);

    CompilationUnit unit =
        parseCompilationUnit2(content, listener, featureSet: featureSet);

    // Assert and return result
    if (codes != null) {
      listener
          .assertErrorsWithCodes(_toFastaGeneratedAnalyzerErrorCodes(codes));
    } else if (errors != null) {
      listener.assertErrors(errors);
    } else {
      listener.assertNoErrors();
    }
    return unit;
  }

  CompilationUnit parseCompilationUnit2(
      String content, GatheringErrorListener listener,
      {LanguageVersionToken languageVersion, FeatureSet featureSet}) {
    featureSet ??= FeatureSet.forTesting();
    var source = StringSource(content, 'parser_test_StringSource.dart');

    // Adjust the feature set based on language version comment.
    void languageVersionChanged(
        fasta.Scanner scanner, LanguageVersionToken languageVersion) {
      featureSet = featureSet.restrictToVersion(
          Version(languageVersion.major, languageVersion.minor, 0));
      scanner.configuration = Scanner.buildConfig(featureSet);
    }

    // Scan tokens
    ScannerResult result = scanString(content,
        includeComments: true,
        configuration: Scanner.buildConfig(featureSet),
        languageVersionChanged: languageVersionChanged);
    _fastaTokens = result.tokens;

    // Run parser
    ErrorReporter errorReporter = ErrorReporter(
      listener,
      source,
      isNonNullableByDefault: false,
    );
    fasta.Parser parser = fasta.Parser(null);
    AstBuilder astBuilder =
        AstBuilder(errorReporter, source.uri, true, featureSet);
    parser.listener = astBuilder;
    astBuilder.parser = parser;
    astBuilder.allowNativeClause = allowNativeClause;
    parser.parseUnit(_fastaTokens);
    CompilationUnitImpl unit = astBuilder.pop();

    expect(unit, isNotNull);
    return unit;
  }

  @override
  ConditionalExpression parseConditionalExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseConstExpression(String code) {
    return _parseExpression(code);
  }

  @override
  ConstructorInitializer parseConstructorInitializer(String code) {
    createParser('class __Test { __Test() : $code; }');
    CompilationUnit unit = _parserProxy.parseCompilationUnit2();
    assertNoErrors();
    var clazz = unit.declarations[0] as ClassDeclaration;
    var constructor = clazz.members[0] as ConstructorDeclaration;
    return constructor.initializers.single;
  }

  @override
  CompilationUnit parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    createParser(source);
    CompilationUnit unit =
        _parserProxy.parseDirectives(_parserProxy.currentToken);
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(0));
    listener.assertErrorsWithCodes(errorCodes);
    return unit;
  }

  @override
  BinaryExpression parseEqualityExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseExpression(String source,
      {List<ErrorCode> codes,
      List<ExpectedError> errors,
      int expectedEndOffset,
      bool inAsync = false,
      FeatureSet featureSet}) {
    createParser(source,
        expectedEndOffset: expectedEndOffset, featureSet: featureSet);
    if (inAsync) {
      _parserProxy.fastaParser.asyncState = AsyncModifier.Async;
    }
    Expression result = _parserProxy.parseExpression2();
    assertErrors(codes: codes, errors: errors);
    return result;
  }

  @override
  List<Expression> parseExpressionList(String code) {
    return (_parseExpression('[$code]') as ListLiteral)
        .elements
        .toList()
        .cast<Expression>();
  }

  @override
  Expression parseExpressionWithoutCascade(String code) {
    return _parseExpression(code);
  }

  @override
  FormalParameter parseFormalParameter(String code, ParameterKind kind,
      {List<ErrorCode> errorCodes = const <ErrorCode>[]}) {
    String parametersCode;
    if (kind == ParameterKind.REQUIRED) {
      parametersCode = '($code)';
    } else if (kind == ParameterKind.POSITIONAL) {
      parametersCode = '([$code])';
    } else if (kind == ParameterKind.NAMED) {
      parametersCode = '({$code})';
    } else {
      fail('$kind');
    }
    FormalParameterList list = parseFormalParameterList(parametersCode,
        inFunctionType: false, errorCodes: errorCodes);
    return list.parameters.single;
  }

  @override
  FormalParameterList parseFormalParameterList(String code,
      {bool inFunctionType = false,
      List<ErrorCode> errorCodes = const <ErrorCode>[],
      List<ExpectedError> errors}) {
    createParser(code);
    FormalParameterList result =
        _parserProxy.parseFormalParameterList(inFunctionType: inFunctionType);
    assertErrors(codes: errors != null ? null : errorCodes, errors: errors);
    return result;
  }

  @override
  CompilationUnitMember parseFullCompilationUnitMember() {
    return _parserProxy.parseTopLevelDeclaration(false);
  }

  @override
  Directive parseFullDirective() {
    return _parserProxy.parseTopLevelDeclaration(true);
  }

  @override
  FunctionExpression parseFunctionExpression(String code) {
    return _parseExpression(code);
  }

  @override
  InstanceCreationExpression parseInstanceCreationExpression(
      String code, analyzer.Token newToken) {
    return _parseExpression('$newToken $code');
  }

  @override
  ListLiteral parseListLiteral(
      analyzer.Token token, String typeArgumentsCode, String code) {
    String sc = '';
    if (token != null) {
      sc += token.lexeme + ' ';
    }
    if (typeArgumentsCode != null) {
      sc += typeArgumentsCode;
    }
    sc += code;
    return _parseExpression(sc);
  }

  @override
  TypedLiteral parseListOrMapLiteral(analyzer.Token modifier, String code) {
    String literalCode = modifier != null ? '$modifier $code' : code;
    return parsePrimaryExpression(literalCode) as TypedLiteral;
  }

  @override
  Expression parseLogicalAndExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseLogicalOrExpression(String code) {
    return _parseExpression(code);
  }

  @override
  SetOrMapLiteral parseMapLiteral(
      analyzer.Token token, String typeArgumentsCode, String code) {
    String sc = '';
    if (token != null) {
      sc += token.lexeme + ' ';
    }
    if (typeArgumentsCode != null) {
      sc += typeArgumentsCode;
    }
    sc += code;
    return parsePrimaryExpression(sc) as SetOrMapLiteral;
  }

  @override
  MapLiteralEntry parseMapLiteralEntry(String code) {
    var mapLiteral = parseMapLiteral(null, null, '{ $code }');
    return mapLiteral.elements.single;
  }

  @override
  Expression parseMultiplicativeExpression(String code) {
    return _parseExpression(code);
  }

  @override
  InstanceCreationExpression parseNewExpression(String code) {
    return _parseExpression(code);
  }

  @override
  NormalFormalParameter parseNormalFormalParameter(String code,
      {bool inFunctionType = false,
      List<ErrorCode> errorCodes = const <ErrorCode>[]}) {
    FormalParameterList list = parseFormalParameterList('($code)',
        inFunctionType: inFunctionType, errorCodes: errorCodes);
    return list.parameters.single;
  }

  @override
  Expression parsePostfixExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Identifier parsePrefixedIdentifier(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parsePrimaryExpression(String code,
      {int expectedEndOffset, List<ExpectedError> errors}) {
    createParser(code, expectedEndOffset: expectedEndOffset);
    Expression result = _parserProxy.parsePrimaryExpression();
    assertErrors(codes: null, errors: errors);
    return result;
  }

  @override
  Expression parseRelationalExpression(String code) {
    return _parseExpression(code);
  }

  @override
  RethrowExpression parseRethrowExpression(String code) {
    return _parseExpression(code);
  }

  @override
  BinaryExpression parseShiftExpression(String code) {
    return _parseExpression(code);
  }

  @override
  SimpleIdentifier parseSimpleIdentifier(String code) {
    return _parseExpression(code);
  }

  @override
  Statement parseStatement(String source,
      {int expectedEndOffset, FeatureSet featureSet, bool inAsync = false}) {
    createParser(source,
        expectedEndOffset: expectedEndOffset, featureSet: featureSet);
    if (inAsync) {
      _parserProxy.fastaParser.asyncState = AsyncModifier.Async;
    }
    Statement statement = _parserProxy.parseStatement2();
    assertErrors(codes: NO_ERROR_COMPARISON);
    return statement;
  }

  @override
  Expression parseStringLiteral(String code) {
    return _parseExpression(code);
  }

  @override
  SymbolLiteral parseSymbolLiteral(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseThrowExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseThrowExpressionWithoutCascade(String code) {
    return _parseExpression(code);
  }

  @override
  PrefixExpression parseUnaryExpression(String code) {
    return _parseExpression(code);
  }

  @override
  VariableDeclarationList parseVariableDeclarationList(String code) {
    var statement = parseStatement('$code;') as VariableDeclarationStatement;
    return statement.variables;
  }

  Expression _parseExpression(String code) {
    var statement = parseStatement('$code;') as ExpressionStatement;
    return statement.expression;
  }

  ErrorCode _toFastaGeneratedAnalyzerErrorCode(ErrorCode code) {
    if (code == ParserErrorCode.ABSTRACT_ENUM ||
        code == ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION ||
        code == ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE ||
        code == ParserErrorCode.ABSTRACT_TYPEDEF ||
        code == ParserErrorCode.CONST_ENUM ||
        code == ParserErrorCode.CONST_TYPEDEF ||
        code == ParserErrorCode.COVARIANT_TOP_LEVEL_DECLARATION ||
        code == ParserErrorCode.FINAL_CLASS ||
        code == ParserErrorCode.FINAL_ENUM ||
        code == ParserErrorCode.FINAL_TYPEDEF ||
        code == ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION) {
      return ParserErrorCode.EXTRANEOUS_MODIFIER;
    }
    return code;
  }

  List<ErrorCode> _toFastaGeneratedAnalyzerErrorCodes(
          List<ErrorCode> expectedErrorCodes) =>
      expectedErrorCodes.map(_toFastaGeneratedAnalyzerErrorCode).toList();
}

/// Tests of the fasta parser based on [FormalParameterParserTestMixin].
@reflectiveTest
class FormalParameterParserTest_Fasta extends FastaParserTestCase
    with FormalParameterParserTestMixin {
  FormalParameter parseNNBDFormalParameter(String code, ParameterKind kind,
      {List<ExpectedError> errors}) {
    String parametersCode;
    if (kind == ParameterKind.REQUIRED) {
      parametersCode = '($code)';
    } else if (kind == ParameterKind.POSITIONAL) {
      parametersCode = '([$code])';
    } else if (kind == ParameterKind.NAMED) {
      parametersCode = '({$code})';
    } else {
      fail('$kind');
    }
    createParser(parametersCode, featureSet: nonNullable);
    FormalParameterList list =
        _parserProxy.parseFormalParameterList(inFunctionType: false);
    assertErrors(errors: errors);
    return list.parameters.single;
  }

  void test_fieldFormalParameter_function_nullable() {
    var parameter =
        parseNNBDFormalParameter('void this.a()?', ParameterKind.REQUIRED);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    FieldFormalParameter functionParameter = parameter;
    expect(functionParameter.type, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNotNull);
    expect(functionParameter.endToken, functionParameter.question);
  }

  void test_functionTyped_named_nullable() {
    ParameterKind kind = ParameterKind.NAMED;
    var defaultParameter =
        parseNNBDFormalParameter('a()? : null', kind) as DefaultFormalParameter;
    var functionParameter =
        defaultParameter.parameter as FunctionTypedFormalParameter;
    assertNoErrors();
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.isNamed, isTrue);
    expect(functionParameter.question, isNotNull);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_functionTyped_named_nullable_disabled() {
    ParameterKind kind = ParameterKind.NAMED;
    var defaultParameter = parseFormalParameter('a()? : null', kind,
            errorCodes: [ParserErrorCode.EXPERIMENT_NOT_ENABLED])
        as DefaultFormalParameter;
    var functionParameter =
        defaultParameter.parameter as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.isNamed, isTrue);
    expect(functionParameter.question, isNotNull);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_functionTyped_positional_nullable_disabled() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    var defaultParameter = parseFormalParameter('a()? = null', kind,
            errorCodes: [ParserErrorCode.EXPERIMENT_NOT_ENABLED])
        as DefaultFormalParameter;
    var functionParameter =
        defaultParameter.parameter as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.isOptionalPositional, isTrue);
    expect(functionParameter.question, isNotNull);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_functionTyped_required_nullable_disabled() {
    ParameterKind kind = ParameterKind.REQUIRED;
    var functionParameter = parseFormalParameter('a()?', kind,
            errorCodes: [ParserErrorCode.EXPERIMENT_NOT_ENABLED])
        as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.isRequiredPositional, isTrue);
    expect(functionParameter.question, isNotNull);
  }

  void test_parseFormalParameter_covariant_required_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseNNBDFormalParameter(
        'covariant required A a : null', kind,
        errors: [expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 12, 8)]);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_final_required_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseNNBDFormalParameter(
        'final required a : null', kind,
        errors: [expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 8, 8)]);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_required_covariant_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseNNBDFormalParameter('required covariant A a : null', kind);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_required_final_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseNNBDFormalParameter('required final a : null', kind);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_required_type_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseNNBDFormalParameter('required A a : null', kind);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_required_var_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseNNBDFormalParameter('required var a : null', kind);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_var_required_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseNNBDFormalParameter(
        'var required a : null', kind,
        errors: [expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 6, 8)]);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseNormalFormalParameter_function_noType_nullable() {
    NormalFormalParameter parameter =
        parseNNBDFormalParameter('a()?', ParameterKind.REQUIRED);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNotNull);
    expect(functionParameter.endToken, functionParameter.question);
  }
}

/// Tests of the fasta parser based on [ComplexParserTestMixin].
@reflectiveTest
class NNBDParserTest_Fasta extends FastaParserTestCase {
  @override
  CompilationUnit parseCompilationUnit(String content,
          {List<ErrorCode> codes,
          List<ExpectedError> errors,
          FeatureSet featureSet}) =>
      super.parseCompilationUnit(content,
          codes: codes, errors: errors, featureSet: featureSet ?? nonNullable);

  void test_assignment_complex() {
    parseCompilationUnit('D? foo(X? x) { X? x1; X? x2 = x + bar(7); }');
  }

  void test_assignment_complex2() {
    parseCompilationUnit(r'''
main() {
  A? a;
  String? s = '';
  a?..foo().length..x27 = s!..toString().length;
}
''');
  }

  void test_assignment_simple() {
    parseCompilationUnit('D? foo(X? x) { X? x1; X? x2 = x; }');
  }

  void test_bangBeforeFuctionCall1() {
    // https://github.com/dart-lang/sdk/issues/39776
    var unit = parseCompilationUnit('f() { Function? f1; f1!(42); }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement1 = body.block.statements[0] as VariableDeclarationStatement;
    expect(statement1.toSource(), "Function? f1;");
    var statement2 = body.block.statements[1] as ExpressionStatement;

    // expression is "f1!(42)"
    var expression = statement2.expression as FunctionExpressionInvocation;
    expect(expression.toSource(), "f1!(42)");

    var functionExpression = expression.function as PostfixExpression;
    SimpleIdentifier identifier = functionExpression.operand;
    expect(identifier.name, 'f1');
    expect(functionExpression.operator.lexeme, '!');

    expect(expression.typeArguments, null);

    expect(expression.argumentList.arguments.length, 1);
    IntegerLiteral argument = expression.argumentList.arguments.single;
    expect(argument.value, 42);
  }

  void test_bangBeforeFuctionCall2() {
    // https://github.com/dart-lang/sdk/issues/39776
    var unit = parseCompilationUnit('f() { Function f2; f2!<int>(42); }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement1 = body.block.statements[0] as VariableDeclarationStatement;
    expect(statement1.toSource(), "Function f2;");
    var statement2 = body.block.statements[1] as ExpressionStatement;

    // expression is "f2!<int>(42)"
    var expression = statement2.expression as FunctionExpressionInvocation;
    expect(expression.toSource(), "f2!<int>(42)");

    var functionExpression = expression.function as PostfixExpression;
    SimpleIdentifier identifier = functionExpression.operand;
    expect(identifier.name, 'f2');
    expect(functionExpression.operator.lexeme, '!');

    expect(expression.typeArguments.arguments.length, 1);
    TypeName typeArgument = expression.typeArguments.arguments.single;
    expect(typeArgument.name.name, "int");

    expect(expression.argumentList.arguments.length, 1);
    IntegerLiteral argument = expression.argumentList.arguments.single;
    expect(argument.value, 42);
  }

  void test_bangQuestionIndex() {
    // http://dartbug.com/41177
    CompilationUnit unit = parseCompilationUnit('f(dynamic a) { a!?[0]; }');
    FunctionDeclaration funct = unit.declarations[0];
    BlockFunctionBody body = funct.functionExpression.body;

    ExpressionStatement statement = body.block.statements[0];
    IndexExpression expression = statement.expression;

    IntegerLiteral index = expression.index;
    expect(index.value, 0);

    Token question = expression.question;
    expect(question, isNotNull);
    expect(question.lexeme, "?");

    PostfixExpression target = expression.target;
    SimpleIdentifier identifier = target.operand;
    expect(identifier.name, 'a');
    expect(target.operator.lexeme, '!');
  }

  void test_binary_expression_statement() {
    final unit = parseCompilationUnit('D? foo(X? x) { X ?? x2; }');
    FunctionDeclaration funct = unit.declarations[0];
    BlockFunctionBody body = funct.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    BinaryExpression expression = statement.expression;
    SimpleIdentifier lhs = expression.leftOperand;
    expect(lhs.name, 'X');
    expect(expression.operator.lexeme, '??');
    SimpleIdentifier rhs = expression.rightOperand;
    expect(rhs.name, 'x2');
  }

  void test_cascade_withNullCheck_indexExpression() {
    var unit = parseCompilationUnit('main() { a?..[27]; }');
    FunctionDeclaration funct = unit.declarations[0];
    BlockFunctionBody body = funct.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    CascadeExpression cascade = statement.expression;
    IndexExpression indexExpression = cascade.cascadeSections[0];
    expect(indexExpression.period.lexeme, '?..');
    expect(indexExpression.toSource(), '?..[27]');
  }

  void test_cascade_withNullCheck_invalid() {
    parseCompilationUnit('main() { a..[27]?..x; }', errors: [
      expectedError(ParserErrorCode.NULL_AWARE_CASCADE_OUT_OF_ORDER, 16, 3),
    ]);
  }

  void test_cascade_withNullCheck_methodInvocation() {
    var unit = parseCompilationUnit('main() { a?..foo(); }');
    FunctionDeclaration funct = unit.declarations[0];
    BlockFunctionBody body = funct.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    CascadeExpression cascade = statement.expression;
    MethodInvocation invocation = cascade.cascadeSections[0];
    expect(invocation.operator.lexeme, '?..');
    expect(invocation.toSource(), '?..foo()');
  }

  void test_cascade_withNullCheck_propertyAccess() {
    var unit = parseCompilationUnit('main() { a?..x27; }');
    FunctionDeclaration funct = unit.declarations[0];
    BlockFunctionBody body = funct.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    CascadeExpression cascade = statement.expression;
    PropertyAccess propertyAccess = cascade.cascadeSections[0];
    expect(propertyAccess.operator.lexeme, '?..');
    expect(propertyAccess.toSource(), '?..x27');
  }

  void test_conditional() {
    parseCompilationUnit('D? foo(X? x) { X ? 7 : y; }');
  }

  void test_conditional_complex() {
    parseCompilationUnit('D? foo(X? x) { X ? x2 = x + bar(7) : y; }');
  }

  void test_conditional_error() {
    parseCompilationUnit('D? foo(X? x) { X ? ? x2 = x + bar(7) : y; }',
        errors: [
          expectedError(ParserErrorCode.MISSING_IDENTIFIER, 19, 1),
          expectedError(ParserErrorCode.EXPECTED_TOKEN, 40, 1),
          expectedError(ParserErrorCode.MISSING_IDENTIFIER, 40, 1),
        ]);
  }

  void test_conditional_simple() {
    parseCompilationUnit('D? foo(X? x) { X ? x2 = x : y; }');
  }

  void test_enableNonNullable_false() {
    parseCompilationUnit('main() { x is String? ? (x + y) : z; }',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 20, 1)],
        featureSet: preNonNullable);
  }

  void test_for() {
    parseCompilationUnit('main() { for(int x = 0; x < 7; ++x) { } }');
  }

  void test_for_conditional() {
    parseCompilationUnit('main() { for(x ? y = 7 : y = 8; y < 10; ++y) { } }');
  }

  void test_for_nullable() {
    parseCompilationUnit('main() { for(int? x = 0; x < 7; ++x) { } }');
  }

  void test_foreach() {
    parseCompilationUnit('main() { for(int x in [7]) { } }');
  }

  void test_foreach_nullable() {
    parseCompilationUnit('main() { for(int? x in [7, null]) { } }');
  }

  void test_functionTypedFormalParameter_nullable_disabled() {
    parseCompilationUnit('void f(void p()?) {}',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 15, 1)],
        featureSet: preNonNullable);
  }

  test_fuzz_38113() async {
    // https://github.com/dart-lang/sdk/issues/38113
    await parseCompilationUnit(r'+t{{r?this}}', errors: [
      expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 0, 1),
      expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 1, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 4),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 1),
    ]);
  }

  void test_gft_nullable() {
    parseCompilationUnit('main() { C? Function() x = 7; }');
  }

  void test_gft_nullable_1() {
    parseCompilationUnit('main() { C Function()? x = 7; }');
  }

  void test_gft_nullable_2() {
    parseCompilationUnit('main() { C? Function()? x = 7; }');
  }

  void test_gft_nullable_3() {
    parseCompilationUnit('main() { C? Function()? Function()? x = 7; }');
  }

  void test_gft_nullable_prefixed() {
    parseCompilationUnit('main() { C.a? Function()? x = 7; }');
  }

  void test_indexed() {
    CompilationUnit unit = parseCompilationUnit('main() { a[7]; }');
    FunctionDeclaration method = unit.declarations[0];
    BlockFunctionBody body = method.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    IndexExpression expression = statement.expression;
    expect(expression.leftBracket.lexeme, '[');
  }

  void test_indexed_nullAware() {
    CompilationUnit unit = parseCompilationUnit('main() { a?.[7]; }');
    FunctionDeclaration method = unit.declarations[0];
    BlockFunctionBody body = method.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    IndexExpression expression = statement.expression;
    expect(expression.leftBracket.lexeme, '?.[');
    expect(expression.rightBracket.lexeme, ']');
    expect(expression.leftBracket.endGroup, expression.rightBracket);
  }

  void test_indexed_nullAware_optOut() {
    CompilationUnit unit = parseCompilationUnit('''
// @dart = 2.2
main() { a?.[7]; }''',
        errors: [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 27, 1)]);
    FunctionDeclaration method = unit.declarations[0];
    BlockFunctionBody body = method.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    PropertyAccess expression = statement.expression;
    expect(expression.target.toSource(), 'a');
    expect(expression.operator.lexeme, '?.');
  }

  void test_indexExpression_nullable_disabled() {
    parseCompilationUnit('main(a) { a?[0]; }',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 11, 1)],
        featureSet: preNonNullable);
  }

  void test_is_nullable() {
    CompilationUnit unit =
        parseCompilationUnit('main() { x is String? ? (x + y) : z; }');
    FunctionDeclaration function = unit.declarations[0];
    BlockFunctionBody body = function.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    ConditionalExpression expression = statement.expression;

    IsExpression condition = expression.condition;
    expect((condition.type as NamedType).question, isNotNull);
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
  }

  void test_is_nullable_parenthesis() {
    CompilationUnit unit =
        parseCompilationUnit('main() { (x is String?) ? (x + y) : z; }');
    FunctionDeclaration function = unit.declarations[0];
    BlockFunctionBody body = function.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    ConditionalExpression expression = statement.expression;

    ParenthesizedExpression condition = expression.condition;
    IsExpression isExpression = condition.expression;
    expect((isExpression.type as NamedType).question, isNotNull);
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
  }

  void test_is_nullable_parenthesis_optOut() {
    parseCompilationUnit('''
// @dart = 2.2
main() { (x is String?) ? (x + y) : z; }
''', errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 36, 1)]);
  }

  void test_late_as_identifier() {
    parseCompilationUnit('''
class C {
  int late;
}

void f(C c) {
  print(c.late);
}

main() {
  f(new C());
}
''', featureSet: preNonNullable);
  }

  void test_late_as_identifier_optOut() {
    parseCompilationUnit('''
// @dart = 2.2
class C {
  int late;
}

void f(C c) {
  print(c.late);
}

main() {
  f(new C());
}
''');
  }

  void test_nullableTypeInInitializerList_01() {
    // http://dartbug.com/40834
    var unit = parseCompilationUnit(r'''
class Foo {
  String? x;
  int y;

  Foo(Object? o) : x = o as String?, y = 0;
}
''');
    ClassDeclaration classDeclaration = unit.declarations.first;
    ConstructorDeclaration constructor = classDeclaration.getConstructor(null);

    // Object? o
    SimpleFormalParameter parameter = constructor.parameters.parameters.single;
    expect(parameter.identifier.name, 'o');
    TypeName type = parameter.type;
    expect(type.question.lexeme, '?');
    expect(type.name.name, 'Object');

    expect(constructor.initializers.length, 2);

    // o as String?
    {
      ConstructorFieldInitializer initializer = constructor.initializers[0];
      expect(initializer.fieldName.name, 'x');
      AsExpression expression = initializer.expression;
      SimpleIdentifier identifier = expression.expression;
      expect(identifier.name, 'o');
      TypeName expressionType = expression.type;
      expect(expressionType.question.lexeme, '?');
      expect(expressionType.name.name, 'String');
    }

    // y = 0
    {
      ConstructorFieldInitializer initializer = constructor.initializers[1];
      expect(initializer.fieldName.name, 'y');
      IntegerLiteral expression = initializer.expression;
      expect(expression.value, 0);
    }
  }

  void test_nullableTypeInInitializerList_02() {
    var unit = parseCompilationUnit(r'''
class Foo {
  String? x;
  int y;

  Foo(Object? o) : y = o is String? ? o.length : null, x = null;
}
''');
    ClassDeclaration classDeclaration = unit.declarations.first;
    ConstructorDeclaration constructor = classDeclaration.getConstructor(null);

    // Object? o
    SimpleFormalParameter parameter = constructor.parameters.parameters.single;
    expect(parameter.identifier.name, 'o');
    TypeName type = parameter.type;
    expect(type.question.lexeme, '?');
    expect(type.name.name, 'Object');

    expect(constructor.initializers.length, 2);

    // y = o is String? ? o.length : null
    {
      ConstructorFieldInitializer initializer = constructor.initializers[0];
      expect(initializer.fieldName.name, 'y');
      ConditionalExpression expression = initializer.expression;
      IsExpression condition = expression.condition;
      SimpleIdentifier identifier = condition.expression;
      expect(identifier.name, 'o');
      TypeName expressionType = condition.type;
      expect(expressionType.question.lexeme, '?');
      expect(expressionType.name.name, 'String');
      PrefixedIdentifier thenExpression = expression.thenExpression;
      expect(thenExpression.identifier.name, 'length');
      expect(thenExpression.prefix.name, 'o');
      NullLiteral elseExpression = expression.elseExpression;
      expect(elseExpression, isNotNull);
    }

    // x = null
    {
      ConstructorFieldInitializer initializer = constructor.initializers[1];
      expect(initializer.fieldName.name, 'x');
      NullLiteral expression = initializer.expression;
      expect(expression, isNotNull);
    }
  }

  void test_nullableTypeInInitializerList_03() {
    // As test_nullableTypeInInitializerList_02 but without ? on String in is.
    var unit = parseCompilationUnit(r'''
class Foo {
  String? x;
  int y;

  Foo(Object? o) : y = o is String ? o.length : null, x = null;
}
''');
    ClassDeclaration classDeclaration = unit.declarations.first;
    ConstructorDeclaration constructor = classDeclaration.getConstructor(null);

    // Object? o
    SimpleFormalParameter parameter = constructor.parameters.parameters.single;
    expect(parameter.identifier.name, 'o');
    TypeName type = parameter.type;
    expect(type.question.lexeme, '?');
    expect(type.name.name, 'Object');

    expect(constructor.initializers.length, 2);

    // y = o is String ? o.length : null
    {
      ConstructorFieldInitializer initializer = constructor.initializers[0];
      expect(initializer.fieldName.name, 'y');
      ConditionalExpression expression = initializer.expression;
      IsExpression condition = expression.condition;
      SimpleIdentifier identifier = condition.expression;
      expect(identifier.name, 'o');
      TypeName expressionType = condition.type;
      expect(expressionType.question, isNull);
      expect(expressionType.name.name, 'String');
      PrefixedIdentifier thenExpression = expression.thenExpression;
      expect(thenExpression.identifier.name, 'length');
      expect(thenExpression.prefix.name, 'o');
      NullLiteral elseExpression = expression.elseExpression;
      expect(elseExpression, isNotNull);
    }

    // x = null
    {
      ConstructorFieldInitializer initializer = constructor.initializers[1];
      expect(initializer.fieldName.name, 'x');
      NullLiteral expression = initializer.expression;
      expect(expression, isNotNull);
    }
  }

  void test_nullCheck() {
    var unit = parseCompilationUnit('f(int? y) { var x = y!; }');
    FunctionDeclaration function = unit.declarations[0];
    BlockFunctionBody body = function.functionExpression.body;
    VariableDeclarationStatement statement = body.block.statements[0];
    PostfixExpression expression = statement.variables.variables[0].initializer;
    SimpleIdentifier identifier = expression.operand;
    expect(identifier.name, 'y');
    expect(expression.operator.lexeme, '!');
  }

  void test_nullCheck_disabled() {
    var unit = parseCompilationUnit('f(int? y) { var x = y!; }',
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 5, 1),
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 21, 1),
        ],
        featureSet: preNonNullable);
    FunctionDeclaration function = unit.declarations[0];
    BlockFunctionBody body = function.functionExpression.body;
    VariableDeclarationStatement statement = body.block.statements[0];
    SimpleIdentifier identifier = statement.variables.variables[0].initializer;
    expect(identifier.name, 'y');
  }

  void test_nullCheckAfterGetterAccess() {
    parseCompilationUnit('f() { var x = g.x!.y + 7; }');
  }

  void test_nullCheckAfterMethodCall() {
    parseCompilationUnit('f() { var x = g.m()!.y + 7; }');
  }

  void test_nullCheckBeforeGetterAccess() {
    parseCompilationUnit('f() { var x = g!.x + 7; }');
  }

  void test_nullCheckBeforeIndex() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { foo.bar!.baz[arg]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    expect(expression.index.toSource(), 'arg');
    var propertyAccess = expression.target as PropertyAccess;
    expect(propertyAccess.propertyName.toSource(), 'baz');
    var target = propertyAccess.target as PostfixExpression;
    expect(target.operand.toSource(), 'foo.bar');
    expect(target.operator.lexeme, '!');
  }

  void test_nullCheckBeforeMethodCall() {
    parseCompilationUnit('f() { var x = g!.m() + 7; }');
  }

  void test_nullCheckFunctionResult() {
    parseCompilationUnit('f() { var x = g()! + 7; }');
  }

  void test_nullCheckIndexedValue() {
    parseCompilationUnit('f(int? y) { var x = y[0]! + 7; }');
  }

  void test_nullCheckIndexedValue2() {
    parseCompilationUnit('f(int? y) { var x = super.y[0]! + 7; }');
  }

  void test_nullCheckInExpression() {
    parseCompilationUnit('f(int? y) { var x = y! + 7; }');
  }

  void test_nullCheckInExpression_disabled() {
    parseCompilationUnit('f(int? y) { var x = y! + 7; }',
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 5, 1),
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 21, 1),
        ],
        featureSet: preNonNullable);
  }

  void test_nullCheckMethodResult() {
    parseCompilationUnit('f() { var x = g.m()! + 7; }');
  }

  void test_nullCheckMethodResult2() {
    parseCompilationUnit('f() { var x = g?.m()! + 7; }');
  }

  void test_nullCheckMethodResult3() {
    parseCompilationUnit('f() { var x = super.m()! + 7; }');
  }

  void test_nullCheckOnConstConstructor() {
    parseCompilationUnit('f() { var x = const Foo()!; }');
  }

  void test_nullCheckOnConstructor() {
    parseCompilationUnit('f() { var x = new Foo()!; }');
  }

  void test_nullCheckOnIndex() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { obj![arg]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    var target = expression.target as PostfixExpression;
    expect(target.operand.toSource(), 'obj');
    expect(target.operator.lexeme, '!');
  }

  void test_nullCheckOnIndex2() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { obj![arg]![arg2]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    expect(expression.index.toSource(), 'arg2');
    var target = expression.target as PostfixExpression;
    expect(target.operator.lexeme, '!');
    expression = target.operand as IndexExpression;
    expect(expression.index.toSource(), 'arg');
    target = expression.target as PostfixExpression;
    expect(target.operator.lexeme, '!');
    expect(target.operand.toSource(), 'obj');
  }

  void test_nullCheckOnIndex3() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { foo.bar![arg]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    expect(expression.index.toSource(), 'arg');
    var target = expression.target as PostfixExpression;
    expect(target.operand.toSource(), 'foo.bar');
    expect(target.operator.lexeme, '!');
  }

  void test_nullCheckOnIndex4() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { foo!.bar![arg]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    var fooBarTarget = expression.target as PostfixExpression;
    expect(fooBarTarget.toSource(), "foo!.bar!");
    var propertyAccess = fooBarTarget.operand as PropertyAccess;
    var targetFoo = propertyAccess.target as PostfixExpression;
    expect(targetFoo.operand.toSource(), "foo");
    expect(targetFoo.operator.lexeme, "!");
    expect(propertyAccess.propertyName.toSource(), "bar");
    expect(fooBarTarget.operator.lexeme, '!');
    expect(expression.index.toSource(), 'arg');
  }

  void test_nullCheckOnIndex5() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { foo.bar![arg]![arg2]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    expect(expression.index.toSource(), 'arg2');
    var target = expression.target as PostfixExpression;
    expect(target.operator.lexeme, '!');
    expression = target.operand as IndexExpression;
    expect(expression.index.toSource(), 'arg');
    target = expression.target as PostfixExpression;
    expect(target.operator.lexeme, '!');
    expect(target.operand.toSource(), 'foo.bar');
  }

  void test_nullCheckOnIndex6() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { foo!.bar![arg]![arg2]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;

    // expression is "foo!.bar![arg]![arg2]"
    var expression = statement.expression as IndexExpression;
    expect(expression.index.toSource(), 'arg2');

    // target is "foo!.bar![arg]!"
    var target = expression.target as PostfixExpression;
    expect(target.operator.lexeme, '!');

    // expression is "foo!.bar![arg]"
    expression = target.operand as IndexExpression;
    expect(expression.index.toSource(), 'arg');

    // target is "foo!.bar!"
    target = expression.target as PostfixExpression;
    expect(target.operator.lexeme, '!');

    // propertyAccess is "foo!.bar"
    PropertyAccess propertyAccess = target.operand as PropertyAccess;
    expect(propertyAccess.propertyName.toSource(), "bar");

    // target is "foo!"
    target = propertyAccess.target as PostfixExpression;
    expect(target.operator.lexeme, '!');

    expect(target.operand.toSource(), "foo");
  }

  void test_nullCheckOnLiteral_disabled() {
    parseCompilationUnit('f() { var x = 0!; }',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 15, 1)],
        featureSet: preNonNullable);
  }

  void test_nullCheckOnLiteralDouble() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = 1.2!; }');
  }

  void test_nullCheckOnLiteralInt() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = 0!; }');
  }

  void test_nullCheckOnLiteralList() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = [1,2]!; }');
  }

  void test_nullCheckOnLiteralMap() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = {1:2}!; }');
  }

  void test_nullCheckOnLiteralSet() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = {1,2}!; }');
  }

  void test_nullCheckOnLiteralString() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = "seven"!; }');
  }

  void test_nullCheckOnNull() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = null!; }');
  }

  void test_nullCheckOnSend() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { obj!(arg); }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as FunctionExpressionInvocation;
    var target = expression.function as PostfixExpression;
    expect(target.operand.toSource(), 'obj');
    expect(target.operator.lexeme, '!');
  }

  void test_nullCheckOnSend2() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { obj!(arg)!(arg2); }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as FunctionExpressionInvocation;
    expect(expression.argumentList.toSource(), '(arg2)');
    var target = expression.function as PostfixExpression;
    expect(target.operator.lexeme, '!');
    expression = target.operand as FunctionExpressionInvocation;
    expect(expression.argumentList.toSource(), '(arg)');
    target = expression.function as PostfixExpression;
    expect(target.operator.lexeme, '!');
    expect(target.operand.toSource(), 'obj');
  }

  void test_nullCheckOnSymbol() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = #seven!; }');
  }

  void test_nullCheckOnValue() {
    parseCompilationUnit('f(Point p) { var x = p.y! + 7; }');
  }

  void test_nullCheckOnValue_disabled() {
    parseCompilationUnit('f(Point p) { var x = p.y! + 7; }',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 24, 1)],
        featureSet: preNonNullable);
  }

  void test_nullCheckParenthesizedExpression() {
    parseCompilationUnit('f(int? y) { var x = (y)! + 7; }');
  }

  void test_nullCheckPropertyAccess() {
    parseCompilationUnit('f() { var x = g.p! + 7; }');
  }

  void test_nullCheckPropertyAccess2() {
    parseCompilationUnit('f() { var x = g?.p! + 7; }');
  }

  void test_nullCheckPropertyAccess3() {
    parseCompilationUnit('f() { var x = super.p! + 7; }');
  }

  void test_postfix_null_assertion_and_unary_prefix_operator_precedence() {
    // -x! is parsed as -(x!).
    var unit = parseCompilationUnit('void main() { -x!; }');
    var function = unit.declarations[0] as FunctionDeclaration;
    var body = function.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var outerExpression = statement.expression as PrefixExpression;
    expect(outerExpression.operator.type, TokenType.MINUS);
    var innerExpression = outerExpression.operand as PostfixExpression;
    expect(innerExpression.operator.type, TokenType.BANG);
  }

  void test_postfix_null_assertion_of_postfix_expression() {
    // x++! is parsed as (x++)!.
    var unit = parseCompilationUnit('void main() { x++!; }');
    var function = unit.declarations[0] as FunctionDeclaration;
    var body = function.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var outerExpression = statement.expression as PostfixExpression;
    expect(outerExpression.operator.type, TokenType.BANG);
    var innerExpression = outerExpression.operand as PostfixExpression;
    expect(innerExpression.operator.type, TokenType.PLUS_PLUS);
  }

  void test_typeName_nullable_disabled() {
    parseCompilationUnit('int? x;',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 3, 1)],
        featureSet: preNonNullable);
  }
}

/// Proxy implementation of the analyzer parser, implemented in terms of the
/// Fasta parser.
///
/// This allows many of the analyzer parser tests to be run on Fasta, even if
/// they call into the analyzer parser class directly.
class ParserProxy extends analyzer.ParserAdapter {
  /// The error listener to which scanner and parser errors will be reported.
  final GatheringErrorListener _errorListener;

  ForwardingTestListener _eventListener;

  final int expectedEndOffset;

  /// Creates a [ParserProxy] which is prepared to begin parsing at the given
  /// Fasta token.
  factory ParserProxy(analyzer.Token firstToken, FeatureSet featureSet,
      {bool allowNativeClause = false, int expectedEndOffset}) {
    TestSource source = TestSource();
    var errorListener = GatheringErrorListener(checkRanges: true);
    var errorReporter = ErrorReporter(
      errorListener,
      source,
      isNonNullableByDefault: false,
    );
    return ParserProxy._(
        firstToken, errorReporter, null, errorListener, featureSet,
        allowNativeClause: allowNativeClause,
        expectedEndOffset: expectedEndOffset);
  }

  ParserProxy._(analyzer.Token firstToken, ErrorReporter errorReporter,
      Uri fileUri, this._errorListener, FeatureSet featureSet,
      {bool allowNativeClause = false, this.expectedEndOffset})
      : super(firstToken, errorReporter, fileUri, featureSet,
            allowNativeClause: allowNativeClause) {
    _eventListener = ForwardingTestListener(astBuilder);
    fastaParser.listener = _eventListener;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Annotation parseAnnotation() {
    return _run('MetadataStar', () => super.parseAnnotation());
  }

  @override
  ArgumentList parseArgumentList() {
    return _run('unspecified', () => super.parseArgumentList());
  }

  @override
  ClassMember parseClassMember(String className) {
    return _run('ClassOrMixinBody', () => super.parseClassMember(className));
  }

  @override
  List<Combinator> parseCombinators() {
    return _run('Import', () => super.parseCombinators());
  }

  @override
  List<CommentReference> parseCommentReferences(
      List<DocumentationCommentToken> tokens) {
    for (int index = 0; index < tokens.length - 1; ++index) {
      analyzer.Token next = tokens[index].next;
      if (next == null) {
        tokens[index].setNext(tokens[index + 1]);
      } else {
        expect(next, tokens[index + 1]);
      }
    }
    expect(tokens[tokens.length - 1].next, isNull);
    List<CommentReference> references =
        astBuilder.parseCommentReferences(tokens.first);
    if (astBuilder.stack.isNotEmpty) {
      throw 'Expected empty stack, but found:'
          '\n  ${astBuilder.stack.values.join('\n  ')}';
    }
    return references;
  }

  @override
  CompilationUnit parseCompilationUnit2() {
    CompilationUnit result = super.parseCompilationUnit2();
    expect(currentToken.isEof, isTrue, reason: currentToken.lexeme);
    expect(astBuilder.stack, hasLength(0));
    _eventListener.expectEmpty();
    return result;
  }

  @override
  Configuration parseConfiguration() {
    return _run('ConditionalUris', () => super.parseConfiguration());
  }

  @override
  DottedName parseDottedName() {
    return _run('unspecified', () => super.parseDottedName());
  }

  @override
  Expression parseExpression2() {
    return _run('unspecified', () => super.parseExpression2());
  }

  @override
  FormalParameterList parseFormalParameterList({bool inFunctionType = false}) {
    return _run('unspecified',
        () => super.parseFormalParameterList(inFunctionType: inFunctionType));
  }

  @override
  FunctionBody parseFunctionBody(
      bool mayBeEmpty, ParserErrorCode emptyErrorCode, bool inExpression) {
    Token lastToken;
    FunctionBody body = _run('unspecified', () {
      FunctionBody body =
          super.parseFunctionBody(mayBeEmpty, emptyErrorCode, inExpression);
      lastToken = currentToken;
      currentToken = currentToken.next;
      return body;
    });
    if (!inExpression) {
      if (![';', '}'].contains(lastToken.lexeme)) {
        fail('Expected ";" or "}", but found: ${lastToken.lexeme}');
      }
    }
    return body;
  }

  @override
  Expression parsePrimaryExpression() {
    return _run('unspecified', () => super.parsePrimaryExpression());
  }

  @override
  Statement parseStatement(Token token) {
    return _run('unspecified', () => super.parseStatement(token));
  }

  @override
  Statement parseStatement2() {
    return _run('unspecified', () => super.parseStatement2());
  }

  @override
  AnnotatedNode parseTopLevelDeclaration(bool isDirective) {
    return _run(
        'CompilationUnit', () => super.parseTopLevelDeclaration(isDirective));
  }

  @override
  TypeAnnotation parseTypeAnnotation(bool inExpression) {
    return _run('unspecified', () => super.parseTypeAnnotation(inExpression));
  }

  @override
  TypeArgumentList parseTypeArgumentList() {
    return _run('unspecified', () => super.parseTypeArgumentList());
  }

  @override
  TypeName parseTypeName(bool inExpression) {
    return _run('unspecified', () => super.parseTypeName(inExpression));
  }

  @override
  TypeParameter parseTypeParameter() {
    return _run('unspecified', () => super.parseTypeParameter());
  }

  @override
  TypeParameterList parseTypeParameterList() {
    return _run('unspecified', () => super.parseTypeParameterList());
  }

  /// Runs the specified function and returns the result. It checks the
  /// enclosing listener events, that the parse consumed all of the tokens, and
  /// that the result stack is empty.
  _run(String enclosingEvent, Function() f) {
    _eventListener.begin(enclosingEvent);

    // Simulate error handling of parseUnit by skipping error tokens
    // before parsing and reporting them after parsing is complete.
    Token errorToken = currentToken;
    currentToken = fastaParser.skipErrorTokens(currentToken);
    var result = f();
    fastaParser.reportAllErrorTokens(errorToken);

    _eventListener.end(enclosingEvent);

    String lexeme = currentToken is ErrorToken
        ? currentToken.runtimeType.toString()
        : currentToken.lexeme;
    if (expectedEndOffset == null) {
      expect(currentToken.isEof, isTrue, reason: lexeme);
    } else {
      expect(currentToken.offset, expectedEndOffset, reason: lexeme);
    }
    expect(astBuilder.stack, hasLength(0));
    expect(astBuilder.directives, hasLength(0));
    expect(astBuilder.declarations, hasLength(0));
    return result;
  }
}

@reflectiveTest
class RecoveryParserTest_Fasta extends FastaParserTestCase
    with RecoveryParserTestMixin {
  @override
  void test_equalityExpression_precedence_relational_right() {
    parseExpression("== is", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }

  void test_incompleteForEach2() {
    ForStatement statement =
        parseStatement('for (String item i) {}', featureSet: controlFlow);
    listener.assertErrors([
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 4),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 17, 1)
    ]);
    expect(statement.toSource(), 'for (String item; i;) {}');
    ForPartsWithDeclarations forLoopParts = statement.forLoopParts;
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.leftSeparator.type, TokenType.SEMICOLON);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.rightSeparator.type, TokenType.SEMICOLON);
  }

  void test_invalidTypeParameters_super() {
    parseCompilationUnit('class C<X super Y> {}', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 1),
    ]);
  }

  @override
  void test_relationalExpression_missing_LHS_RHS() {
    parseExpression("is", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }

  @override
  void test_relationalExpression_precedence_shift_right() {
    parseExpression("<< is", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }
}

@reflectiveTest
class SimpleParserTest_Fasta extends FastaParserTestCase
    with SimpleParserTestMixin {
  void test_method_name_notNull_37733() {
    // https://github.com/dart-lang/sdk/issues/37733
    var unit = parseCompilationUnit(r'class C { f(<T>()); }', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 12, 1),
    ]);
    var classDeclaration = unit.declarations[0] as ClassDeclaration;
    var method = classDeclaration.members[0] as MethodDeclaration;
    expect(method.parameters.parameters, hasLength(1));
    var parameter =
        method.parameters.parameters[0] as FunctionTypedFormalParameter;
    expect(parameter.identifier, isNotNull);
  }

  test_parseArgument() {
    Expression result = parseArgument('3');
    expect(result, const TypeMatcher<IntegerLiteral>());
    IntegerLiteral literal = result;
    expect(literal.value, 3);
  }

  test_parseArgument_named() {
    Expression result = parseArgument('foo: "a"');
    expect(result, const TypeMatcher<NamedExpression>());
    NamedExpression expression = result;
    StringLiteral literal = expression.expression;
    expect(literal.stringValue, 'a');
  }

  @failingTest
  @override
  void test_parseCommentReferences_skipLink_direct_multiLine() =>
      super.test_parseCommentReferences_skipLink_direct_multiLine();

  @failingTest
  @override
  void test_parseCommentReferences_skipLink_reference_multiLine() =>
      super.test_parseCommentReferences_skipLink_reference_multiLine();

  void test_parseVariableDeclaration_final_late() {
    var statement = parseStatement('final late a;', featureSet: nonNullable)
        as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertErrors(
        errors: [expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 6, 4)]);
    expect(declarationList.keyword.lexeme, 'final');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late() {
    var statement = parseStatement('late a;', featureSet: nonNullable)
        as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertNoErrors();
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_final() {
    var statement = parseStatement('late final a;', featureSet: nonNullable)
        as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertNoErrors();
    expect(declarationList.keyword.lexeme, 'final');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_init() {
    var statement = parseStatement('late a = 0;', featureSet: nonNullable)
        as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertNoErrors();
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_type() {
    var statement = parseStatement('late A a;', featureSet: nonNullable)
        as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertNoErrors();
    expect(declarationList.lateKeyword, isNotNull);
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclaration_late_var() {
    var statement = parseStatement('late var a;', featureSet: nonNullable)
        as VariableDeclarationStatement;
    var declarationList = statement.variables;
    assertNoErrors();
    expect(declarationList.lateKeyword, isNotNull);
    expect(declarationList.keyword?.lexeme, 'var');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_typeAlias_37733() {
    // https://github.com/dart-lang/sdk/issues/37733
    var unit = parseCompilationUnit(r'typedef K=Function(<>($', errors: [
      expectedError(CompileTimeErrorCode.INVALID_INLINE_FUNCTION_TYPE, 19, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 19, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 20, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 22, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 23, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 23, 1),
    ]);
    var typeAlias = unit.declarations[0] as GenericTypeAlias;
    expect(typeAlias.name.toSource(), 'K');
    var functionType = typeAlias.functionType;
    expect(functionType.parameters.parameters, hasLength(1));
    var parameter = functionType.parameters.parameters[0];
    expect(parameter.identifier, isNotNull);
  }

  void test_typeAlias_parameter_missingIdentifier_37733() {
    // https://github.com/dart-lang/sdk/issues/37733
    var unit = parseCompilationUnit(r'typedef T=Function(<S>());', errors: [
      expectedError(CompileTimeErrorCode.INVALID_INLINE_FUNCTION_TYPE, 19, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 19, 1),
    ]);
    var typeAlias = unit.declarations[0] as GenericTypeAlias;
    expect(typeAlias.name.toSource(), 'T');
    var functionType = typeAlias.functionType;
    expect(functionType.parameters.parameters, hasLength(1));
    var parameter = functionType.parameters.parameters[0];
    expect(parameter.identifier, isNotNull);
  }
}

/// Tests of the fasta parser based on [StatementParserTestMixin].
@reflectiveTest
class StatementParserTest_Fasta extends FastaParserTestCase
    with StatementParserTestMixin {
  void test_35177() {
    ExpressionStatement statement = parseStatement('(f)()<int>();');

    FunctionExpressionInvocation funct1 = statement.expression;
    NodeList<TypeAnnotation> typeArgs = funct1.typeArguments.arguments;
    expect(typeArgs, hasLength(1));
    TypeName typeName = typeArgs[0];
    expect(typeName.name.name, 'int');
    expect(funct1.argumentList.arguments, hasLength(0));

    FunctionExpressionInvocation funct2 = funct1.function;
    expect(funct2.typeArguments, isNull);
    expect(funct2.argumentList.arguments, hasLength(0));

    ParenthesizedExpression expression = funct2.function;
    SimpleIdentifier identifier = expression.expression;
    expect(identifier.name, 'f');
  }

  void test_invalid_typeArg_34850() {
    var unit = parseCompilationUnit('foo Future<List<int>> bar() {}', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 11, 4),
      expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 4, 6),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 22, 3),
    ]);
    // Validate that recovery has properly updated the token stream.
    analyzer.Token token = unit.beginToken;
    while (!token.isEof) {
      expect(token.type, isNot(TokenType.GT_GT));
      analyzer.Token next = token.next;
      expect(next.previous, token);
      token = next;
    }
  }

  void test_parseForStatement_each_await2() {
    ForStatement forStatement = parseStatement(
      'await for (element in list) {}',
      inAsync: true,
      featureSet: controlFlow,
    );
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNotNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForEachPartsWithIdentifier forLoopParts = forStatement.forLoopParts;
    expect(forLoopParts.identifier, isNotNull);
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_finalExternal() {
    ForStatement forStatement = parseStatement(
      'for (final external in list) {}',
      featureSet: controlFlow,
    );
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForEachPartsWithDeclaration forLoopParts = forStatement.forLoopParts;
    expect(forLoopParts.loopVariable.identifier.name, 'external');
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_finalRequired() {
    ForStatement forStatement = parseStatement(
      'for (final required in list) {}',
      featureSet: controlFlow,
    );
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForEachPartsWithDeclaration forLoopParts = forStatement.forLoopParts;
    expect(forLoopParts.loopVariable.identifier.name, 'required');
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_genericFunctionType2() {
    ForStatement forStatement = parseStatement(
      'for (void Function<T>(T) element in list) {}',
      featureSet: controlFlow,
    );
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForEachPartsWithDeclaration forLoopParts = forStatement.forLoopParts;
    expect(forLoopParts.loopVariable, isNotNull);
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_identifier2() {
    ForStatement forStatement = parseStatement(
      'for (element in list) {}',
      featureSet: controlFlow,
    );
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForEachPartsWithIdentifier forLoopParts = forStatement.forLoopParts;
    expect(forLoopParts.identifier, isNotNull);
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_noType_metadata2() {
    ForStatement forStatement = parseStatement(
      'for (@A var element in list) {}',
      featureSet: controlFlow,
    );
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForEachPartsWithDeclaration forLoopParts = forStatement.forLoopParts;
    expect(forLoopParts.loopVariable, isNotNull);
    expect(forLoopParts.loopVariable.metadata, hasLength(1));
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_type2() {
    ForStatement forStatement = parseStatement(
      'for (A element in list) {}',
      featureSet: controlFlow,
    );
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForEachPartsWithDeclaration forLoopParts = forStatement.forLoopParts;
    expect(forLoopParts.loopVariable, isNotNull);
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_var2() {
    ForStatement forStatement = parseStatement(
      'for (var element in list) {}',
      featureSet: controlFlow,
    );
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForEachPartsWithDeclaration forLoopParts = forStatement.forLoopParts;
    expect(forLoopParts.loopVariable, isNotNull);
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_c2() {
    ForStatement forStatement = parseStatement(
      'for (; i < count;) {}',
      featureSet: controlFlow,
    );
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForPartsWithExpression forLoopParts = forStatement.forLoopParts;
    expect(forLoopParts.initialization, isNull);
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNotNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_cu2() {
    ForStatement forStatement = parseStatement(
      'for (; i < count; i++) {}',
      featureSet: controlFlow,
    );
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForPartsWithExpression forLoopParts = forStatement.forLoopParts;
    expect(forLoopParts.initialization, isNull);
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNotNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_ecu2() {
    ForStatement forStatement = parseStatement(
      'for (i--; i < count; i++) {}',
      featureSet: spread,
    );
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForPartsWithExpression forLoopParts = forStatement.forLoopParts;
    expect(forLoopParts.initialization, isNotNull);
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNotNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_i2() {
    ForStatement forStatement = parseStatement(
      'for (var i = 0;;) {}',
      featureSet: spread,
    );
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForPartsWithDeclarations forLoopParts = forStatement.forLoopParts;
    VariableDeclarationList variables = forLoopParts.variables;
    expect(variables, isNotNull);
    expect(variables.metadata, hasLength(0));
    expect(variables.variables, hasLength(1));
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_i_withMetadata2() {
    ForStatement forStatement = parseStatement(
      'for (@A var i = 0;;) {}',
      featureSet: spread,
    );
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForPartsWithDeclarations forLoopParts = forStatement.forLoopParts;
    VariableDeclarationList variables = forLoopParts.variables;
    expect(variables, isNotNull);
    expect(variables.metadata, hasLength(1));
    expect(variables.variables, hasLength(1));
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_ic2() {
    ForStatement forStatement = parseStatement(
      'for (var i = 0; i < count;) {}',
      featureSet: spread,
    );
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForPartsWithDeclarations forLoopParts = forStatement.forLoopParts;
    VariableDeclarationList variables = forLoopParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNotNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_icu2() {
    ForStatement forStatement = parseStatement(
      'for (var i = 0; i < count; i++) {}',
      featureSet: spread,
    );
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForPartsWithDeclarations forLoopParts = forStatement.forLoopParts;
    VariableDeclarationList variables = forLoopParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNotNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_iicuu2() {
    ForStatement forStatement = parseStatement(
      'for (int i = 0, j = count; i < j; i++, j--) {}',
      featureSet: spread,
    );
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForPartsWithDeclarations forLoopParts = forStatement.forLoopParts;
    VariableDeclarationList variables = forLoopParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(2));
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNotNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(2));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_iu2() {
    ForStatement forStatement = parseStatement(
      'for (var i = 0;; i++) {}',
      featureSet: spread,
    );
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForPartsWithDeclarations forLoopParts = forStatement.forLoopParts;
    VariableDeclarationList variables = forLoopParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_u2() {
    ForStatement forStatement = parseStatement(
      'for (;; i++) {}',
      featureSet: spread,
    );
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    ForPartsWithExpression forLoopParts = forStatement.forLoopParts;
    expect(forLoopParts.initialization, isNull);
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_partial_typeArg1_34850() {
    var unit = parseCompilationUnit('<bar<', errors: [
      expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 0, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 5, 0),
      expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 1, 3),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 5, 0),
    ]);
    // Validate that recovery has properly updated the token stream.
    analyzer.Token token = unit.beginToken;
    while (!token.isEof) {
      expect(token.type, isNot(TokenType.GT_GT));
      analyzer.Token next = token.next;
      expect(next.previous, token);
      token = next;
    }
  }

  void test_partial_typeArg2_34850() {
    var unit = parseCompilationUnit('foo <bar<', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 5, 3),
      expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 0, 3),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 9, 0),
    ]);
    // Validate that recovery has properly updated the token stream.
    analyzer.Token token = unit.beginToken;
    while (!token.isEof) {
      expect(token.type, isNot(TokenType.GT_GT));
      analyzer.Token next = token.next;
      expect(next.previous, token);
      token = next;
    }
  }
}

/// Tests of the fasta parser based on [TopLevelParserTestMixin].
@reflectiveTest
class TopLevelParserTest_Fasta extends FastaParserTestCase
    with TopLevelParserTestMixin {
  void test_parseClassDeclaration_native_allowed() {
    allowNativeClause = true;
    test_parseClassDeclaration_native();
  }

  void test_parseClassDeclaration_native_allowedWithFields() {
    allowNativeClause = true;
    createParser(r'''
class A native 'something' {
  final int x;
  A() {}
}
''');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
  }

  void test_parseClassDeclaration_native_missing_literal() {
    createParser('class A native {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    if (allowNativeClause) {
      assertNoErrors();
    } else {
      assertErrorsWithCodes([
        ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION,
      ]);
    }
    expect(member, TypeMatcher<ClassDeclaration>());
    ClassDeclaration declaration = member;
    expect(declaration.nativeClause, isNotNull);
    expect(declaration.nativeClause.nativeKeyword, isNotNull);
    expect(declaration.nativeClause.name, isNull);
    expect(declaration.endToken.type, TokenType.CLOSE_CURLY_BRACKET);
  }

  void test_parseClassDeclaration_native_missing_literal_allowed() {
    allowNativeClause = true;
    test_parseClassDeclaration_native_missing_literal();
  }

  void test_parseClassDeclaration_native_missing_literal_not_allowed() {
    allowNativeClause = false;
    test_parseClassDeclaration_native_missing_literal();
  }

  void test_parseClassDeclaration_native_not_allowed() {
    allowNativeClause = false;
    test_parseClassDeclaration_native();
  }

  void test_parseMixinDeclaration_empty() {
    createParser('mixin A {}');
    MixinDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    expect(declaration.onClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.name, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_implements() {
    createParser('mixin A implements B {}');
    MixinDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    expect(declaration.onClause, isNull);
    ImplementsClause implementsClause = declaration.implementsClause;
    expect(implementsClause.implementsKeyword, isNotNull);
    NodeList<TypeName> interfaces = implementsClause.interfaces;
    expect(interfaces, hasLength(1));
    expect(interfaces[0].name.name, 'B');
    expect(interfaces[0].typeArguments, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.name, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_implements2() {
    createParser('mixin A implements B<T>, C {}');
    MixinDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    expect(declaration.onClause, isNull);
    ImplementsClause implementsClause = declaration.implementsClause;
    expect(implementsClause.implementsKeyword, isNotNull);
    NodeList<TypeName> interfaces = implementsClause.interfaces;
    expect(interfaces, hasLength(2));
    expect(interfaces[0].name.name, 'B');
    expect(interfaces[0].typeArguments.arguments, hasLength(1));
    expect(interfaces[1].name.name, 'C');
    expect(interfaces[1].typeArguments, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.name, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_metadata() {
    createParser('@Z mixin A {}');
    MixinDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    NodeList<Annotation> metadata = declaration.metadata;
    expect(metadata, hasLength(1));
    expect(metadata[0].name.name, 'Z');
    expect(declaration.documentationComment, isNull);
    expect(declaration.onClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.name, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_on() {
    createParser('mixin A on B {}');
    MixinDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    OnClause onClause = declaration.onClause;
    expect(onClause.onKeyword, isNotNull);
    NodeList<TypeName> constraints = onClause.superclassConstraints;
    expect(constraints, hasLength(1));
    expect(constraints[0].name.name, 'B');
    expect(constraints[0].typeArguments, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.name, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_on2() {
    createParser('mixin A on B, C<T> {}');
    MixinDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    OnClause onClause = declaration.onClause;
    expect(onClause.onKeyword, isNotNull);
    NodeList<TypeName> constraints = onClause.superclassConstraints;
    expect(constraints, hasLength(2));
    expect(constraints[0].name.name, 'B');
    expect(constraints[0].typeArguments, isNull);
    expect(constraints[1].name.name, 'C');
    expect(constraints[1].typeArguments.arguments, hasLength(1));
    expect(declaration.implementsClause, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.name, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_onAndImplements() {
    createParser('mixin A on B implements C {}');
    MixinDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    OnClause onClause = declaration.onClause;
    expect(onClause.onKeyword, isNotNull);
    NodeList<TypeName> constraints = onClause.superclassConstraints;
    expect(constraints, hasLength(1));
    expect(constraints[0].name.name, 'B');
    expect(constraints[0].typeArguments, isNull);
    ImplementsClause implementsClause = declaration.implementsClause;
    expect(implementsClause.implementsKeyword, isNotNull);
    NodeList<TypeName> interfaces = implementsClause.interfaces;
    expect(interfaces, hasLength(1));
    expect(interfaces[0].name.name, 'C');
    expect(interfaces[0].typeArguments, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.name, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_simple() {
    createParser('''
mixin A {
  int f;
  int get g => f;
  set s(int v) {f = v;}
  int add(int v) => f = f + v;
}''');
    MixinDeclaration declaration = parseFullCompilationUnitMember();
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    expect(declaration.onClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.name, 'A');
    expect(declaration.members, hasLength(4));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_withDocumentationComment() {
    createParser('/// Doc\nmixin M {}');
    MixinDeclaration declaration = parseFullCompilationUnitMember();
    expectCommentText(declaration.documentationComment, '/// Doc');
  }

  void test_parseTopLevelVariable_final_late() {
    var unit = parseCompilationUnit('final late a;',
        featureSet: nonNullable,
        errors: [expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 6, 4)]);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    var declarationList = declaration.variables;
    expect(declarationList.keyword.lexeme, 'final');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseTopLevelVariable_late() {
    var unit = parseCompilationUnit('late a;',
        featureSet: nonNullable,
        errors: [
          expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 5, 1)
        ]);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    var declarationList = declaration.variables;
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseTopLevelVariable_late_final() {
    var unit = parseCompilationUnit('late final a;', featureSet: nonNullable);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    var declarationList = declaration.variables;
    expect(declarationList.keyword.lexeme, 'final');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseTopLevelVariable_late_init() {
    var unit = parseCompilationUnit('late a = 0;',
        featureSet: nonNullable,
        errors: [
          expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 5, 1)
        ]);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    var declarationList = declaration.variables;
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseTopLevelVariable_late_type() {
    var unit = parseCompilationUnit('late A a;', featureSet: nonNullable);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    var declarationList = declaration.variables;
    expect(declarationList.lateKeyword, isNotNull);
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }
}

@reflectiveTest
class VarianceParserTest_Fasta extends FastaParserTestCase {
  @override
  CompilationUnit parseCompilationUnit(String content,
      {List<ErrorCode> codes,
      List<ExpectedError> errors,
      FeatureSet featureSet}) {
    return super.parseCompilationUnit(content,
        codes: codes,
        errors: errors,
        featureSet: featureSet ??
            FeatureSet.forTesting(
              sdkVersion: '2.5.0',
              additionalFeatures: [Feature.variance],
            ));
  }

  void test_class_disabled_multiple() {
    parseCompilationUnit('class A<in T, inout U, out V> { }',
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 8, 2),
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 14, 5),
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 23, 3)
        ],
        featureSet: FeatureSet.forTesting(sdkVersion: '2.5.0'));
  }

  void test_class_disabled_single() {
    parseCompilationUnit('class A<out T> { }',
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 8, 3),
        ],
        featureSet: FeatureSet.forTesting(sdkVersion: '2.5.0'));
  }

  void test_class_enabled_multiple() {
    var unit = parseCompilationUnit('class A<in T, inout U, out V, W> { }');
    expect(unit.declarations, hasLength(1));
    var classDecl = unit.declarations[0] as ClassDeclaration;
    expect(classDecl.name.name, 'A');

    expect(classDecl.typeParameters.typeParameters, hasLength(4));
    expect(classDecl.typeParameters.typeParameters[0].name.name, 'T');
    expect(classDecl.typeParameters.typeParameters[1].name.name, 'U');
    expect(classDecl.typeParameters.typeParameters[2].name.name, 'V');
    expect(classDecl.typeParameters.typeParameters[3].name.name, 'W');

    var typeParameterImplList = classDecl.typeParameters.typeParameters;
    expect((typeParameterImplList[0] as TypeParameterImpl).varianceKeyword,
        isNotNull);
    expect(
        (typeParameterImplList[0] as TypeParameterImpl).varianceKeyword.lexeme,
        "in");
    expect((typeParameterImplList[1] as TypeParameterImpl).varianceKeyword,
        isNotNull);
    expect(
        (typeParameterImplList[1] as TypeParameterImpl).varianceKeyword.lexeme,
        "inout");
    expect((typeParameterImplList[2] as TypeParameterImpl).varianceKeyword,
        isNotNull);
    expect(
        (typeParameterImplList[2] as TypeParameterImpl).varianceKeyword.lexeme,
        "out");
    expect((typeParameterImplList[3] as TypeParameterImpl).varianceKeyword,
        isNull);
  }

  void test_class_enabled_multipleVariances() {
    var unit = parseCompilationUnit('class A<in out inout T> { }', errors: [
      expectedError(ParserErrorCode.MULTIPLE_VARIANCE_MODIFIERS, 11, 3),
      expectedError(ParserErrorCode.MULTIPLE_VARIANCE_MODIFIERS, 15, 5)
    ]);
    expect(unit.declarations, hasLength(1));
    var classDecl = unit.declarations[0] as ClassDeclaration;
    expect(classDecl.name.name, 'A');
    expect(classDecl.typeParameters.typeParameters, hasLength(1));
    expect(classDecl.typeParameters.typeParameters[0].name.name, 'T');
  }

  void test_class_enabled_single() {
    var unit = parseCompilationUnit('class A<in T> { }');
    expect(unit.declarations, hasLength(1));
    var classDecl = unit.declarations[0] as ClassDeclaration;
    expect(classDecl.name.name, 'A');
    expect(classDecl.typeParameters.typeParameters, hasLength(1));
    expect(classDecl.typeParameters.typeParameters[0].name.name, 'T');

    var typeParameterImpl =
        classDecl.typeParameters.typeParameters[0] as TypeParameterImpl;
    expect(typeParameterImpl.varianceKeyword, isNotNull);
    expect(typeParameterImpl.varianceKeyword.lexeme, "in");
  }

  void test_function_disabled() {
    parseCompilationUnit('void A(in int value) {}',
        errors: [
          expectedError(ParserErrorCode.MISSING_IDENTIFIER, 7, 2),
          expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 3),
        ],
        featureSet: FeatureSet.forTesting(sdkVersion: '2.5.0'));
  }

  void test_function_enabled() {
    parseCompilationUnit('void A(in int value) {}', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 7, 2),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 3),
    ]);
  }

  void test_list_disabled() {
    parseCompilationUnit('List<out String> stringList = [];',
        errors: [
          expectedError(ParserErrorCode.EXPECTED_TOKEN, 9, 6),
        ],
        featureSet: FeatureSet.forTesting(sdkVersion: '2.5.0'));
  }

  void test_list_enabled() {
    parseCompilationUnit('List<out String> stringList = [];', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 9, 6),
    ]);
  }

  void test_mixin_disabled_multiple() {
    parseCompilationUnit('mixin A<inout T, out U> { }',
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 8, 5),
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 17, 3),
        ],
        featureSet: FeatureSet.forTesting(sdkVersion: '2.5.0'));
  }

  void test_mixin_disabled_single() {
    parseCompilationUnit('mixin A<inout T> { }',
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 8, 5),
        ],
        featureSet: FeatureSet.forTesting(sdkVersion: '2.5.0'));
  }

  void test_mixin_enabled_single() {
    var unit = parseCompilationUnit('mixin A<inout T> { }');
    expect(unit.declarations, hasLength(1));
    var mixinDecl = unit.declarations[0] as MixinDeclaration;
    expect(mixinDecl.name.name, 'A');
    expect(mixinDecl.typeParameters.typeParameters, hasLength(1));
    expect(mixinDecl.typeParameters.typeParameters[0].name.name, 'T');
  }

  void test_typedef_disabled() {
    parseCompilationUnit('typedef A<inout X> = X Function(X);',
        errors: [
          expectedError(ParserErrorCode.EXPECTED_TOKEN, 16, 1),
        ],
        featureSet: FeatureSet.forTesting(sdkVersion: '2.5.0'));
  }

  void test_typedef_enabled() {
    parseCompilationUnit('typedef A<inout X> = X Function(X);', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 16, 1),
    ]);
  }
}
