// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' as analyzer;
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
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
import 'package:front_end/src/fasta/parser/async_modifier.dart';
import 'package:front_end/src/fasta/parser/forwarding_listener.dart' as fasta;
import 'package:front_end/src/fasta/parser/parser.dart' as fasta;
import 'package:front_end/src/fasta/scanner.dart'
    show ScannerResult, scanString;
import 'package:front_end/src/fasta/scanner/error_token.dart' show ErrorToken;
import 'package:front_end/src/fasta/scanner/string_scanner.dart';
import 'package:front_end/src/scanner/errors.dart' show translateErrorToken;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'parser_fasta_listener.dart';
import 'parser_test.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassMemberParserTest_Fasta);
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
  });
}

/**
 * Type of the "parse..." methods defined in the Fasta parser.
 */
typedef analyzer.Token ParseFunction(analyzer.Token token);

@reflectiveTest
class ClassMemberParserTest_Fasta extends FastaParserTestCase
    with ClassMemberParserTestMixin {
  void test_parseClassMember_operator_gtgtgt() {
    final sourceText = 'class C { bool operator >>>(other) => false; }';

    // ---------------------------------------------------
    // TODO(danrubel): Replace this section with a call to parseCompilationUnit
    // once '>>>' token support is enabled permanently.

    var source = new StringSource(sourceText, 'parser_test_StringSource.dart');
    GatheringErrorListener errorListener =
        new GatheringErrorListener(checkRanges: true);

    // Scan tokens
    StringScanner scanner = new StringScanner(sourceText, includeComments: true)
      ..enableGtGtGt = true;
    Token tokens = scanner.tokenize();
    expect(scanner.hasErrors, isFalse);

    // Run parser
    ErrorReporter errorReporter = new ErrorReporter(errorListener, source);
    fasta.Parser parser = new fasta.Parser(null);
    AstBuilder astBuilder = new AstBuilder(errorReporter, source.uri, true);
    parser.listener = astBuilder;
    astBuilder.parser = parser;
    parser.parseUnit(tokens);

    CompilationUnitImpl unit = astBuilder.pop();
    expect(unit, isNotNull);
    unit.localDeclarations = astBuilder.localDeclarations;
    errorListener.assertNoErrors();

    // ---------------------------------------------------

    ClassDeclaration declaration = unit.declarations[0];
    ClassMember member = declaration.members[0];
    expect(member, isNotNull);
    expect(member, new TypeMatcher<MethodDeclaration>());
    MethodDeclaration method = member;
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
}

/**
 * Tests of the fasta parser based on [ExpressionParserTestMixin].
 */
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
        parseSpreadCollections: true,
        parseControlFlowCollections: true);
  }

  void test_listLiteral_for() {
    ListLiteral list = parseCollectionLiteral(
      '[1, await for (var x in list) 2]',
      inAsync: true,
    );
    expect(list.elements2, hasLength(2));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);

    ForElement second = list.elements2[1];
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
    expect(list.elements2, hasLength(2));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);

    ForElement second = list.elements2[1];
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
    expect(list.elements2, hasLength(2));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);

    ForElement second = list.elements2[1];
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
    expect(list.elements2, hasLength(2));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);

    IfElement second = list.elements2[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    IntegerLiteral thenElement = second.thenElement;
    expect(thenElement.value, 2);
    expect(second.elseElement, isNull);
  }

  void test_listLiteral_ifElse() {
    ListLiteral list = parseCollectionLiteral('[1, if (true) 2 else 5]');
    expect(list.elements2, hasLength(2));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);

    IfElement second = list.elements2[1];
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
    expect(list.elements2, hasLength(2));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);

    IfElement second = list.elements2[1];
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
    expect(list.elements2, hasLength(2));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);

    IfElement second = list.elements2[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    SpreadElement thenElement = second.thenElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    SpreadElement elseElement = second.elseElement;
    expect(elseElement.spreadOperator.lexeme, '...?');
  }

  void test_listLiteral_ifFor() {
    ListLiteral list = parseCollectionLiteral('[1, if (true) for (a in b) 2]');
    expect(list.elements2, hasLength(2));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);

    IfElement second = list.elements2[1];
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
    expect(list.elements2, hasLength(2));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);

    IfElement second = list.elements2[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    SpreadElement thenElement = second.thenElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    expect(second.elseElement, isNull);
  }

  void test_listLiteral_spread() {
    ListLiteral list = parseCollectionLiteral('[1, ...[2]]');
    expect(list.elements2, hasLength(2));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);

    SpreadElement element = list.elements2[1];
    expect(element.spreadOperator.lexeme, '...');
    ListLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_listLiteral_spreadQ() {
    ListLiteral list = parseCollectionLiteral('[1, ...?[2]]');
    expect(list.elements2, hasLength(2));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);

    SpreadElement element = list.elements2[1];
    expect(element.spreadOperator.lexeme, '...?');
    ListLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_mapLiteral_for() {
    SetOrMapLiteral map = parseCollectionLiteral(
        '{1:7, await for (y in list) 2:3}',
        inAsync: true);
    expect(map.elements2, hasLength(2));
    MapLiteralEntry first = map.elements2[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 7);

    ForElement second = map.elements2[1];
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
    expect(map.elements2, hasLength(2));
    MapLiteralEntry first = map.elements2[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 7);

    ForElement second = map.elements2[1];
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
    expect(map.elements2, hasLength(2));
    MapLiteralEntry first = map.elements2[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 7);

    ForElement second = map.elements2[1];
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
    expect(map.elements2, hasLength(2));
    MapLiteralEntry first = map.elements2[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 1);

    IfElement second = map.elements2[1];
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
    expect(map.elements2, hasLength(2));
    MapLiteralEntry first = map.elements2[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 1);

    IfElement second = map.elements2[1];
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
    expect(map.elements2, hasLength(2));
    MapLiteralEntry first = map.elements2[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 1);

    IfElement second = map.elements2[1];
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
    expect(map.elements2, hasLength(2));
    MapLiteralEntry first = map.elements2[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 7);

    IfElement second = map.elements2[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    SpreadElement thenElement = second.thenElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    SpreadElement elseElement = second.elseElement;
    expect(elseElement.spreadOperator.lexeme, '...?');
    SetOrMapLiteral elseElementExpression = elseElement.expression;
    expect(elseElementExpression.elements2, hasLength(1));
    MapLiteralEntry entry = elseElementExpression.elements2[0];
    IntegerLiteral entryValue = entry.value;
    expect(entryValue.value, 6);
  }

  void test_mapLiteral_ifFor() {
    SetOrMapLiteral map =
        parseCollectionLiteral('{1:1, if (true) for (a in b) 2:4}');
    expect(map.elements2, hasLength(2));
    MapLiteralEntry first = map.elements2[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 1);

    IfElement second = map.elements2[1];
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
    expect(map.elements2, hasLength(2));
    MapLiteralEntry first = map.elements2[0];
    IntegerLiteral firstValue = first.value;
    expect(firstValue.value, 1);

    IfElement second = map.elements2[1];
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
    expect(map.elements2, hasLength(2));

    SpreadElement element = map.elements2[1];
    expect(element.spreadOperator.lexeme, '...');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_mapLiteral_spread2_typed() {
    SetOrMapLiteral map = parseCollectionLiteral('<int, int>{1: 2, ...{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements2, hasLength(2));

    SpreadElement element = map.elements2[1];
    expect(element.spreadOperator.lexeme, '...');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_mapLiteral_spread_typed() {
    SetOrMapLiteral map = parseCollectionLiteral('<int, int>{...{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements2, hasLength(1));

    SpreadElement element = map.elements2[0];
    expect(element.spreadOperator.lexeme, '...');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_mapLiteral_spreadQ() {
    SetOrMapLiteral map = parseCollectionLiteral('{1: 2, ...?{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements2, hasLength(2));

    SpreadElement element = map.elements2[1];
    expect(element.spreadOperator.lexeme, '...?');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_mapLiteral_spreadQ2_typed() {
    SetOrMapLiteral map =
        parseCollectionLiteral('<int, int>{1: 2, ...?{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements2, hasLength(2));

    SpreadElement element = map.elements2[1];
    expect(element.spreadOperator.lexeme, '...?');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_mapLiteral_spreadQ_typed() {
    SetOrMapLiteral map = parseCollectionLiteral('<int, int>{...?{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements2, hasLength(1));

    SpreadElement element = map.elements2[0];
    expect(element.spreadOperator.lexeme, '...?');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_setLiteral_if() {
    SetOrMapLiteral setLiteral = parseCollectionLiteral('{1, if (true) 2}');
    expect(setLiteral.elements2, hasLength(2));
    IntegerLiteral first = setLiteral.elements2[0];
    expect(first.value, 1);

    IfElement second = setLiteral.elements2[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    IntegerLiteral thenElement = second.thenElement;
    expect(thenElement.value, 2);
    expect(second.elseElement, isNull);
  }

  void test_setLiteral_ifElse() {
    SetOrMapLiteral setLiteral =
        parseCollectionLiteral('{1, if (true) 2 else 5}');
    expect(setLiteral.elements2, hasLength(2));
    IntegerLiteral first = setLiteral.elements2[0];
    expect(first.value, 1);

    IfElement second = setLiteral.elements2[1];
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
    expect(setLiteral.elements2, hasLength(2));
    IntegerLiteral first = setLiteral.elements2[0];
    expect(first.value, 1);

    IfElement second = setLiteral.elements2[1];
    BooleanLiteral condition = second.condition;
    expect(condition.value, isTrue);
    SpreadElement thenElement = second.thenElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    SetOrMapLiteral theExpression = thenElement.expression;
    expect(theExpression.elements2, hasLength(1));
    SpreadElement elseElement = second.elseElement;
    expect(elseElement.spreadOperator.lexeme, '...?');
    ListLiteral elseExpression = elseElement.expression;
    expect(elseExpression.elements2, hasLength(1));
  }

  void test_setLiteral_ifSpread() {
    SetOrMapLiteral setLiteral =
        parseCollectionLiteral('{1, if (true) ...[2]}');
    expect(setLiteral.elements2, hasLength(2));
    IntegerLiteral first = setLiteral.elements2[0];
    expect(first.value, 1);

    IfElement second = setLiteral.elements2[1];
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
    expect(set.elements2, hasLength(2));
    IntegerLiteral value = set.elements2[0];
    expect(value.value, 3);

    SpreadElement element = set.elements2[1];
    expect(element.spreadOperator.lexeme, '...');
    ListLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_setLiteral_spread2Q() {
    SetOrMapLiteral set = parseCollectionLiteral('{3, ...?[4]}');
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements2, hasLength(2));
    IntegerLiteral value = set.elements2[0];
    expect(value.value, 3);

    SpreadElement element = set.elements2[1];
    expect(element.spreadOperator.lexeme, '...?');
    ListLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_setLiteral_spread_typed() {
    SetOrMapLiteral set = parseCollectionLiteral('<int>{...[3]}');
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNotNull);
    expect(set.elements2, hasLength(1));

    SpreadElement element = set.elements2[0];
    expect(element.spreadOperator.lexeme, '...');
    ListLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_setLiteral_spreadQ_typed() {
    SetOrMapLiteral set = parseCollectionLiteral('<int>{...?[3]}');
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNotNull);
    expect(set.elements2, hasLength(1));

    SpreadElement element = set.elements2[0];
    expect(element.spreadOperator.lexeme, '...?');
    ListLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_setOrMapLiteral_spread() {
    SetOrMapLiteral map = parseCollectionLiteral('{...{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements2, hasLength(1));

    SpreadElement element = map.elements2[0];
    expect(element.spreadOperator.lexeme, '...');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }

  void test_setOrMapLiteral_spreadQ() {
    SetOrMapLiteral map = parseCollectionLiteral('{...?{3: 4}}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements2, hasLength(1));

    SpreadElement element = map.elements2[0];
    expect(element.spreadOperator.lexeme, '...?');
    SetOrMapLiteral spreadExpression = element.expression;
    expect(spreadExpression.elements2, hasLength(1));
  }
}

/**
 * Tests of the fasta parser based on [ComplexParserTestMixin].
 */
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

/**
 * Tests of the fasta parser based on [ErrorParserTest].
 */
@reflectiveTest
class ErrorParserTest_Fasta extends FastaParserTestCase
    with ErrorParserTestMixin {
  void test_await_missing_async_issue36048() {
    parseCompilationUnit('''
main() { // missing async
  await foo();
}
''', errors: [
      expectedError(CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, 28, 5)
    ]);
  }

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

/**
 * Tests of the fasta parser based on [ExpressionParserTestMixin].
 */
@reflectiveTest
class ExpressionParserTest_Fasta extends FastaParserTestCase
    with ExpressionParserTestMixin {
  void test_listLiteral_spread() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    ListLiteral list = parseExpression('[1, ...[2]]', errors: [
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 4, 3),
    ]);
    expect(list.elements2, hasLength(1));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);
  }

  void test_listLiteral_spreadQ() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    ListLiteral list = parseExpression('[1, ...?[2]]', errors: [
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 4, 4),
    ]);
    expect(list.elements2, hasLength(1));
    IntegerLiteral first = list.elements2[0];
    expect(first.value, 1);
  }

  void test_mapLiteral() {
    SetOrMapLiteral map = parseExpression('{3: 6}');
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements2, hasLength(1));
    MapLiteralEntry entry = map.elements2[0];
    IntegerLiteral key = entry.key;
    expect(key.value, 3);
    IntegerLiteral value = entry.value;
    expect(value.value, 6);
  }

  void test_mapLiteral_const() {
    SetOrMapLiteral map = parseExpression('const {3: 6}');
    expect(map.constKeyword, isNotNull);
    expect(map.typeArguments, isNull);
    expect(map.elements2, hasLength(1));
    MapLiteralEntry entry = map.elements2[0];
    IntegerLiteral key = entry.key;
    expect(key.value, 3);
    IntegerLiteral value = entry.value;
    expect(value.value, 6);
  }

  void test_mapLiteral_invalid_set_entry() {
    SetOrMapLiteral map = parseExpression('<int, int>{1}', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 12, 1),
    ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements2, hasLength(1));
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
    expect(map.elements2, hasLength(0));
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
    expect(map.elements2, hasLength(0));
  }

  void test_mapLiteral_spread() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    SetOrMapLiteral map = parseExpression('{1: 2, ...{3: 4}}', errors: [
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 7, 3),
    ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements2, hasLength(1));
  }

  void test_mapLiteral_spread2_typed() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    SetOrMapLiteral map =
        parseExpression('<int, int>{1: 2, ...{3: 4}}', errors: [
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 17, 3),
    ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements2, hasLength(1));
  }

  void test_mapLiteral_spread_typed() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    SetOrMapLiteral map = parseExpression('<int, int>{...{3: 4}}', errors: [
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 11, 3),
    ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements2, hasLength(0));
  }

  void test_mapLiteral_spreadQ() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    SetOrMapLiteral map = parseExpression('{1: 2, ...?{3: 4}}', errors: [
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 7, 4),
    ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements2, hasLength(1));
  }

  void test_mapLiteral_spreadQ2_typed() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    SetOrMapLiteral map =
        parseExpression('<int, int>{1: 2, ...?{3: 4}}', errors: [
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 17, 4),
    ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements2, hasLength(1));
  }

  void test_mapLiteral_spreadQ_typed() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    SetOrMapLiteral map = parseExpression('<int, int>{...?{3: 4}}', errors: [
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 11, 4),
    ]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements2, hasLength(0));
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
    expect(set.elements2, hasLength(1));
    IntegerLiteral value = set.elements2[0];
    expect(value.value, 3);
  }

  void test_setLiteral_const() {
    SetOrMapLiteral set = parseExpression('const {3, 6}');
    expect(set.constKeyword, isNotNull);
    expect(set.typeArguments, isNull);
    expect(set.elements2, hasLength(2));
    IntegerLiteral value1 = set.elements2[0];
    expect(value1.value, 3);
    IntegerLiteral value2 = set.elements2[1];
    expect(value2.value, 6);
  }

  void test_setLiteral_const_typed() {
    SetOrMapLiteral set = parseExpression('const <int>{3}');
    expect(set.constKeyword, isNotNull);
    expect(set.typeArguments.arguments, hasLength(1));
    NamedType typeArg = set.typeArguments.arguments[0];
    expect(typeArg.name.name, 'int');
    expect(set.elements2.length, 1);
    IntegerLiteral value = set.elements2[0];
    expect(value.value, 3);
  }

  void test_setLiteral_invalid_map_entry() {
    SetOrMapLiteral set = parseExpression('<int>{1: 1}', errors: [
      expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 7, 1),
    ]);
    expect(set.constKeyword, isNull);
    expect(set.typeArguments.arguments, hasLength(1));
    NamedType typeArg = set.typeArguments.arguments[0];
    expect(typeArg.name.name, 'int');
    expect(set.elements2.length, 1);
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
    expect(set.elements2.length, 1);
    SetOrMapLiteral intSet = set.elements2[0];
    expect(intSet.elements2, hasLength(1));
    IntegerLiteral value = intSet.elements2[0];
    expect(value.value, 3);
  }

  void test_setLiteral_spread2() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    SetOrMapLiteral set = parseExpression('{3, ...[4]}',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 4, 3)]);
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements2, hasLength(1));
    IntegerLiteral value = set.elements2[0];
    expect(value.value, 3);
  }

  void test_setLiteral_spread2Q() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    SetOrMapLiteral set = parseExpression('{3, ...?[4]}',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 4, 4)]);
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements2, hasLength(1));
    IntegerLiteral value = set.elements2[0];
    expect(value.value, 3);
  }

  void test_setLiteral_spread_typed() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    SetOrMapLiteral set = parseExpression('<int>{...[3]}',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 6, 3)]);
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNotNull);
    expect(set.elements2, hasLength(0));
  }

  void test_setLiteral_spreadQ_typed() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    SetOrMapLiteral set = parseExpression('<int>{...?[3]}',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 6, 4)]);
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNotNull);
    expect(set.elements2, hasLength(0));
  }

  void test_setLiteral_typed() {
    SetOrMapLiteral set = parseExpression('<int>{3}');
    expect(set.constKeyword, isNull);
    expect(set.typeArguments.arguments, hasLength(1));
    NamedType typeArg = set.typeArguments.arguments[0];
    expect(typeArg.name.name, 'int');
    expect(set.elements2.length, 1);
    IntegerLiteral value = set.elements2[0];
    expect(value.value, 3);
  }

  void test_setOrMapLiteral_spread() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    SetOrMapLiteral map = parseExpression('{...{3: 4}}',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 1, 3)]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements2, hasLength(0));
  }

  void test_setOrMapLiteral_spreadQ() {
    // TODO(danrubel): Remove this once spread_collections is enabled by default
    SetOrMapLiteral map = parseExpression('{...?{3: 4}}',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 1, 4)]);
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements2, hasLength(0));
  }
}

/**
 * Implementation of [AbstractParserTestCase] specialized for testing the
 * Fasta parser.
 */
class FastaParserTestCase
    with ParserTestHelpers
    implements AbstractParserTestCase {
  static final List<ErrorCode> NO_ERROR_COMPARISON = <ErrorCode>[];
  ParserProxy _parserProxy;

  analyzer.Token _fastaTokens;

  @override
  bool allowNativeClause = false;

  @override
  set enableLazyAssignmentOperators(bool value) {
    // Lazy assignment operators are always enabled
  }

  set enableOptionalNewAndConst(bool enable) {
    // ignored
  }

  @override
  set enableUriInPartOf(bool value) {
    if (value == false) {
      throw new UnimplementedError(
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
  void createParser(String content, {int expectedEndOffset}) {
    var scanner = new StringScanner(content, includeComments: true);
    _fastaTokens = scanner.tokenize();
    _parserProxy = new ParserProxy(_fastaTokens,
        allowNativeClause: allowNativeClause,
        expectedEndOffset: expectedEndOffset);
  }

  @override
  ExpectedError expectedError(ErrorCode code, int offset, int length) =>
      new ExpectedError(
          _toFastaGeneratedAnalyzerErrorCode(code), offset, length);

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
      {bool allowConditional: true}) {
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
      bool enableControlFlowCollections}) {
    GatheringErrorListener listener =
        new GatheringErrorListener(checkRanges: true);

    CompilationUnit unit = parseCompilationUnit2(content, listener,
        enableControlFlowCollections: enableControlFlowCollections);

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
      {bool enableControlFlowCollections}) {
    var source = new StringSource(content, 'parser_test_StringSource.dart');

    void reportError(
        ScannerErrorCode errorCode, int offset, List<Object> arguments) {
      listener
          .onError(new AnalysisError(source, offset, 1, errorCode, arguments));
    }

    // Scan tokens
    ScannerResult result = scanString(content, includeComments: true);
    Token token = result.tokens;
    if (result.hasErrors) {
      // The default recovery strategy used by scanString
      // places all error tokens at the head of the stream.
      while (token.type == TokenType.BAD_INPUT) {
        translateErrorToken(token, reportError);
        token = token.next;
      }
    }
    _fastaTokens = token;

    // Run parser
    ErrorReporter errorReporter = new ErrorReporter(listener, source);
    fasta.Parser parser = new fasta.Parser(null);
    AstBuilder astBuilder = new AstBuilder(errorReporter, source.uri, true);
    parser.listener = astBuilder;
    astBuilder.parser = parser;
    astBuilder.allowNativeClause = allowNativeClause;
    if (enableControlFlowCollections != null) {
      astBuilder.enableControlFlowCollections = enableControlFlowCollections;
    }
    parser.parseUnit(_fastaTokens);
    CompilationUnitImpl unit = astBuilder.pop();
    unit.localDeclarations = astBuilder.localDeclarations;

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
      bool parseSpreadCollections = false,
      bool parseControlFlowCollections = false}) {
    createParser(source, expectedEndOffset: expectedEndOffset);
    _parserProxy.astBuilder.enableSpreadCollections = parseSpreadCollections;
    _parserProxy.astBuilder.enableControlFlowCollections =
        parseControlFlowCollections;
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
        .elements2
        .toList()
        .cast<Expression>();
  }

  @override
  Expression parseExpressionWithoutCascade(String code) {
    return _parseExpression(code);
  }

  @override
  FormalParameter parseFormalParameter(String code, ParameterKind kind,
      {List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
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
      {bool inFunctionType: false,
      List<ErrorCode> errorCodes: const <ErrorCode>[],
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
    return mapLiteral.elements2.single;
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
      {bool inFunctionType: false,
      List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
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
      {bool enableLazyAssignmentOperators,
      int expectedEndOffset,
      bool parseSetLiterals = false,
      bool parseSpreadCollections = false,
      bool parseControlFlowCollections = false,
      bool inAsync = false}) {
    createParser(source, expectedEndOffset: expectedEndOffset);
    _parserProxy.astBuilder.enableSpreadCollections = parseSpreadCollections;
    _parserProxy.astBuilder.enableControlFlowCollections =
        parseControlFlowCollections;
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
        code == ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION)
      return ParserErrorCode.EXTRANEOUS_MODIFIER;
    return code;
  }

  List<ErrorCode> _toFastaGeneratedAnalyzerErrorCodes(
          List<ErrorCode> expectedErrorCodes) =>
      expectedErrorCodes.map(_toFastaGeneratedAnalyzerErrorCode).toList();
}

/**
 * Tests of the fasta parser based on [FormalParameterParserTestMixin].
 */
@reflectiveTest
class FormalParameterParserTest_Fasta extends FastaParserTestCase
    with FormalParameterParserTestMixin {}

/**
 * Tests of the fasta parser based on [ComplexParserTestMixin].
 */
@reflectiveTest
class NNBDParserTest_Fasta extends FastaParserTestCase {
  CompilationUnit parseNNBDCompilationUnit(String code,
      {List<ExpectedError> errors}) {
    createParser(code);
    _parserProxy.astBuilder.enableNonNullable = true;
    CompilationUnit unit = _parserProxy.parseCompilationUnit2();
    assertErrors(errors: errors);
    return unit;
  }

  void test_assignment_complex() {
    parseNNBDCompilationUnit('D? foo(X? x) { X? x1; X? x2 = x + bar(7); }');
  }

  void test_assignment_simple() {
    parseNNBDCompilationUnit('D? foo(X? x) { X? x1; X? x2 = x; }');
  }

  void test_binary_expression_statement() {
    final unit = parseNNBDCompilationUnit('D? foo(X? x) { X ?? x2; }');
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

  void test_conditional() {
    parseNNBDCompilationUnit('D? foo(X? x) { X ? 7 : y; }');
  }

  void test_conditional_complex() {
    parseNNBDCompilationUnit('D? foo(X? x) { X ? x2 = x + bar(7) : y; }');
  }

  void test_conditional_error() {
    parseNNBDCompilationUnit('D? foo(X? x) { X ? ? x2 = x + bar(7) : y; }',
        errors: [
          expectedError(ParserErrorCode.MISSING_IDENTIFIER, 19, 1),
          expectedError(ParserErrorCode.EXPECTED_TOKEN, 40, 1),
          expectedError(ParserErrorCode.MISSING_IDENTIFIER, 40, 1),
        ]);
  }

  void test_conditional_simple() {
    parseNNBDCompilationUnit('D? foo(X? x) { X ? x2 = x : y; }');
  }

  void test_enableNonNullable_false() {
    parseCompilationUnit('main() { x is String? ? (x + y) : z; }',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 20, 1)]);
  }

  void test_for() {
    parseNNBDCompilationUnit('main() { for(int x = 0; x < 7; ++x) { } }');
  }

  void test_for_conditional() {
    parseNNBDCompilationUnit(
        'main() { for(x ? y = 7 : y = 8; y < 10; ++y) { } }');
  }

  void test_for_nullable() {
    parseNNBDCompilationUnit('main() { for(int? x = 0; x < 7; ++x) { } }');
  }

  void test_foreach() {
    parseNNBDCompilationUnit('main() { for(int x in [7]) { } }');
  }

  void test_foreach_nullable() {
    parseNNBDCompilationUnit('main() { for(int? x in [7, null]) { } }');
  }

  void test_gft_nullable() {
    parseNNBDCompilationUnit('main() { C? Function() x = 7; }');
  }

  void test_gft_nullable_1() {
    parseNNBDCompilationUnit('main() { C Function()? x = 7; }');
  }

  void test_gft_nullable_2() {
    parseNNBDCompilationUnit('main() { C? Function()? x = 7; }');
  }

  void test_gft_nullable_3() {
    parseNNBDCompilationUnit('main() { C? Function()? Function()? x = 7; }');
  }

  void test_gft_nullable_prefixed() {
    parseNNBDCompilationUnit('main() { C.a? Function()? x = 7; }');
  }

  void test_is_nullable() {
    CompilationUnit unit =
        parseNNBDCompilationUnit('main() { x is String? ? (x + y) : z; }');
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
        parseNNBDCompilationUnit('main() { (x is String?) ? (x + y) : z; }');
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

  void test_nullCheck() {
    var unit = parseNNBDCompilationUnit('f(int? y) { var x = y!; }');
    FunctionDeclaration function = unit.declarations[0];
    BlockFunctionBody body = function.functionExpression.body;
    VariableDeclarationStatement statement = body.block.statements[0];
    PostfixExpression expression = statement.variables.variables[0].initializer;
    SimpleIdentifier identifier = expression.operand;
    expect(identifier.name, 'y');
    expect(expression.operator.lexeme, '!');
  }

  void test_nullCheck_disabled() {
    // TODO(danrubel): remove this once NNBD is enabled by default
    var unit = parseCompilationUnit('f(int? y) { var x = y!; }', errors: [
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 5, 1),
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 21, 1),
    ]);
    FunctionDeclaration function = unit.declarations[0];
    BlockFunctionBody body = function.functionExpression.body;
    VariableDeclarationStatement statement = body.block.statements[0];
    SimpleIdentifier identifier = statement.variables.variables[0].initializer;
    expect(identifier.name, 'y');
  }

  void test_nullCheckFunctionResult() {
    parseNNBDCompilationUnit('f() { var x = g()! + 7; }');
  }

  void test_nullCheckIndexedValue() {
    parseNNBDCompilationUnit('f(int? y) { var x = y[0]! + 7; }');
  }

  void test_nullCheckIndexedValue2() {
    parseNNBDCompilationUnit('f(int? y) { var x = super.y[0]! + 7; }');
  }

  void test_nullCheckInExpression() {
    parseNNBDCompilationUnit('f(int? y) { var x = y! + 7; }');
  }

  void test_nullCheckInExpression_disabled() {
    // TODO(danrubel): remove this once NNBD is enabled by default
    parseCompilationUnit('f(int? y) { var x = y! + 7; }', errors: [
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 5, 1),
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 21, 1),
    ]);
  }

  void test_nullCheckMethodResult() {
    parseNNBDCompilationUnit('f() { var x = g.m()! + 7; }');
  }

  void test_nullCheckMethodResult2() {
    parseNNBDCompilationUnit('f() { var x = g?.m()! + 7; }');
  }

  void test_nullCheckMethodResult3() {
    parseNNBDCompilationUnit('f() { var x = super.m()! + 7; }');
  }

  void test_nullCheckOnConstConstructor() {
    parseNNBDCompilationUnit('f() { var x = const Foo()!; }');
  }

  void test_nullCheckOnConstructor() {
    parseNNBDCompilationUnit('f() { var x = new Foo()!; }');
  }

  void test_nullCheckOnLiteral_disabled() {
    // TODO(danrubel): remove this once NNBD is enabled by default
    parseCompilationUnit('f() { var x = 0!; }',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 15, 1)]);
  }

  void test_nullCheckOnLiteralDouble() {
    // Issues like this should be caught during later analysis
    parseNNBDCompilationUnit('f() { var x = 1.2!; }');
  }

  void test_nullCheckOnLiteralInt() {
    // Issues like this should be caught during later analysis
    parseNNBDCompilationUnit('f() { var x = 0!; }');
  }

  void test_nullCheckOnLiteralList() {
    // Issues like this should be caught during later analysis
    parseNNBDCompilationUnit('f() { var x = [1,2]!; }');
  }

  void test_nullCheckOnLiteralMap() {
    // Issues like this should be caught during later analysis
    parseNNBDCompilationUnit('f() { var x = {1:2}!; }');
  }

  void test_nullCheckOnLiteralSet() {
    // Issues like this should be caught during later analysis
    parseNNBDCompilationUnit('f() { var x = {1,2}!; }');
  }

  void test_nullCheckOnLiteralString() {
    // Issues like this should be caught during later analysis
    parseNNBDCompilationUnit('f() { var x = "seven"!; }');
  }

  void test_nullCheckOnNull() {
    // Issues like this should be caught during later analysis
    parseNNBDCompilationUnit('f() { var x = null!; }');
  }

  void test_nullCheckOnSymbol() {
    // Issues like this should be caught during later analysis
    parseNNBDCompilationUnit('f() { var x = #seven!; }');
  }

  void test_nullCheckOnValue() {
    parseNNBDCompilationUnit('f(Point p) { var x = p.y! + 7; }');
  }

  void test_nullCheckOnValue_disabled() {
    // TODO(danrubel): remove this once NNBD is enabled by default
    parseCompilationUnit('f(Point p) { var x = p.y! + 7; }',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 24, 1)]);
  }

  void test_nullCheckParenthesizedExpression() {
    parseNNBDCompilationUnit('f(int? y) { var x = (y)! + 7; }');
  }

  void test_nullCheckPropertyAccess() {
    parseNNBDCompilationUnit('f() { var x = g.p! + 7; }');
  }

  void test_nullCheckPropertyAccess2() {
    parseNNBDCompilationUnit('f() { var x = g?.p! + 7; }');
  }

  void test_nullCheckPropertyAccess3() {
    parseNNBDCompilationUnit('f() { var x = super.p! + 7; }');
  }
}

/**
 * Proxy implementation of the analyzer parser, implemented in terms of the
 * Fasta parser.
 *
 * This allows many of the analyzer parser tests to be run on Fasta, even if
 * they call into the analyzer parser class directly.
 */
class ParserProxy extends analyzer.ParserAdapter {
  /**
   * The error listener to which scanner and parser errors will be reported.
   */
  final GatheringErrorListener _errorListener;

  ForwardingTestListener _eventListener;

  final int expectedEndOffset;

  /**
   * Creates a [ParserProxy] which is prepared to begin parsing at the given
   * Fasta token.
   */
  factory ParserProxy(analyzer.Token firstToken,
      {bool allowNativeClause: false, int expectedEndOffset}) {
    TestSource source = new TestSource();
    var errorListener = new GatheringErrorListener(checkRanges: true);
    var errorReporter = new ErrorReporter(errorListener, source);
    return new ParserProxy._(firstToken, errorReporter, null, errorListener,
        allowNativeClause: allowNativeClause,
        expectedEndOffset: expectedEndOffset);
  }

  ParserProxy._(analyzer.Token firstToken, ErrorReporter errorReporter,
      Uri fileUri, this._errorListener,
      {bool allowNativeClause: false, this.expectedEndOffset})
      : super(firstToken, errorReporter, fileUri,
            allowNativeClause: allowNativeClause) {
    _eventListener = new ForwardingTestListener(astBuilder);
    fastaParser.listener = _eventListener;
  }

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
  FormalParameterList parseFormalParameterList({bool inFunctionType: false}) {
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

  /**
   * Runs the specified function and returns the result.
   * It checks the enclosing listener events,
   * that the parse consumed all of the tokens,
   * and that the result stack is empty.
   */
  _run(String enclosingEvent, f()) {
    _eventListener.begin(enclosingEvent);
    var result = f();
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
    ForStatement2 statement = parseStatement('for (String item i) {}',
        parseControlFlowCollections: true);
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
      // TODO(danrubel): Improve recovery.
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 1),
      expectedError(ParserErrorCode.MISSING_CLASS_BODY, 10, 5),
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 10, 5),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 10, 5),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 5),
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 16, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 16, 1),
      expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 17, 1),
      expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 19, 1),
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
}

/**
 * Tests of the fasta parser based on [StatementParserTestMixin].
 */
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
    ForStatement2 forStatement = parseStatement(
      'await for (element in list) {}',
      inAsync: true,
      parseControlFlowCollections: true,
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

  void test_parseForStatement_each_genericFunctionType2() {
    ForStatement2 forStatement = parseStatement(
      'for (void Function<T>(T) element in list) {}',
      parseControlFlowCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (element in list) {}',
      parseControlFlowCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (@A var element in list) {}',
      parseControlFlowCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (A element in list) {}',
      parseControlFlowCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (var element in list) {}',
      parseControlFlowCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (; i < count;) {}',
      parseControlFlowCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (; i < count; i++) {}',
      parseControlFlowCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (i--; i < count; i++) {}',
      parseSpreadCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (var i = 0;;) {}',
      parseSpreadCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (@A var i = 0;;) {}',
      parseSpreadCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (var i = 0; i < count;) {}',
      parseSpreadCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (var i = 0; i < count; i++) {}',
      parseSpreadCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (int i = 0, j = count; i < j; i++, j--) {}',
      parseSpreadCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (var i = 0;; i++) {}',
      parseSpreadCollections: true,
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
    ForStatement2 forStatement = parseStatement(
      'for (;; i++) {}',
      parseSpreadCollections: true,
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

/**
 * Tests of the fasta parser based on [TopLevelParserTestMixin].
 */
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
    expect(member, new TypeMatcher<ClassDeclaration>());
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
}
