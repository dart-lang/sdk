// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' as analyzer;
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'parser_test.dart';
import 'parser_test_base.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    // TODO(srawlins): Move each of these test classes into [parser_test.dart];
    // merge with mixins, as each mixin is only used once now; remove this file.
    defineReflectiveTests(CollectionLiteralParserTest);
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
    var list = parseCollectionLiteral(
      '[1, await for (var x in list) 2]',
      inAsync: true,
    ) as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as ForElement;
    expect(second.awaitKeyword, isNotNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    var forLoopParts = second.forLoopParts as ForEachPartsWithDeclaration;
    DeclaredIdentifier forLoopVar = forLoopParts.loopVariable;
    expect(forLoopVar.identifier.name, 'x');
    expect(forLoopParts.inKeyword, isNotNull);
    var iterable = forLoopParts.iterable as SimpleIdentifier;
    expect(iterable.name, 'list');
  }

  void test_listLiteral_forIf() {
    var list = parseCollectionLiteral(
      '[1, await for (var x in list) if (c) 2]',
      inAsync: true,
    ) as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as ForElement;
    expect(second.awaitKeyword, isNotNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    var forLoopParts = second.forLoopParts as ForEachPartsWithDeclaration;
    DeclaredIdentifier forLoopVar = forLoopParts.loopVariable;
    expect(forLoopVar.identifier.name, 'x');
    expect(forLoopParts.inKeyword, isNotNull);
    var iterable = forLoopParts.iterable as SimpleIdentifier;
    expect(iterable.name, 'list');

    var body = second.body as IfElement;
    var condition = body.condition as SimpleIdentifier;
    expect(condition.name, 'c');
    var thenElement = body.thenElement as IntegerLiteral;
    expect(thenElement.value, 2);
  }

  void test_listLiteral_forSpread() {
    var list =
        parseCollectionLiteral('[1, for (int x = 0; x < 10; ++x) ...[2]]')
            as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as ForElement;
    expect(second.awaitKeyword, isNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    var forLoopParts = second.forLoopParts as ForPartsWithDeclarations;
    VariableDeclaration forLoopVar = forLoopParts.variables.variables[0];
    expect(forLoopVar.name.name, 'x');
    var condition = forLoopParts.condition as BinaryExpression;
    var rightOperand = condition.rightOperand as IntegerLiteral;
    expect(rightOperand.value, 10);
    var updater = forLoopParts.updaters[0] as PrefixExpression;
    var updaterOperand = updater.operand as SimpleIdentifier;
    expect(updaterOperand.name, 'x');
  }

  void test_listLiteral_if() {
    var list = parseCollectionLiteral('[1, if (true) 2]') as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as IntegerLiteral;
    expect(thenElement.value, 2);
    expect(second.elseElement, isNull);
  }

  void test_listLiteral_ifElse() {
    var list = parseCollectionLiteral('[1, if (true) 2 else 5]') as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as IntegerLiteral;
    expect(thenElement.value, 2);
    var elseElement = second.elseElement as IntegerLiteral;
    expect(elseElement.value, 5);
  }

  void test_listLiteral_ifElseFor() {
    var list = parseCollectionLiteral('[1, if (true) 2 else for (a in b) 5]')
        as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as IntegerLiteral;
    expect(thenElement.value, 2);

    var elseElement = second.elseElement as ForElement;
    var forLoopParts = elseElement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forLoopParts.identifier.name, 'a');

    var forValue = elseElement.body as IntegerLiteral;
    expect(forValue.value, 5);
  }

  void test_listLiteral_ifElseSpread() {
    var list = parseCollectionLiteral('[1, if (true) ...[2] else ...?[5]]')
        as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as SpreadElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    var elseElement = second.elseElement as SpreadElement;
    expect(elseElement.spreadOperator.lexeme, '...?');
  }

  void test_listLiteral_ifFor() {
    var list =
        parseCollectionLiteral('[1, if (true) for (a in b) 2]') as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);

    var thenElement = second.thenElement as ForElement;
    var forLoopParts = thenElement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forLoopParts.identifier.name, 'a');

    var forValue = thenElement.body as IntegerLiteral;
    expect(forValue.value, 2);
    expect(second.elseElement, isNull);
  }

  void test_listLiteral_ifSpread() {
    var list = parseCollectionLiteral('[1, if (true) ...[2]]') as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as SpreadElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    expect(second.elseElement, isNull);
  }

  void test_listLiteral_spread() {
    var list = parseCollectionLiteral('[1, ...[2]]') as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var element = list.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as ListLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_listLiteral_spreadQ() {
    var list = parseCollectionLiteral('[1, ...?[2]]') as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var element = list.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as ListLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_for() {
    var map = parseCollectionLiteral('{1:7, await for (y in list) 2:3}',
        inAsync: true) as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 7);

    var second = map.elements[1] as ForElement;
    expect(second.awaitKeyword, isNotNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    var forLoopParts = second.forLoopParts as ForEachPartsWithIdentifier;
    SimpleIdentifier forLoopVar = forLoopParts.identifier;
    expect(forLoopVar.name, 'y');
    expect(forLoopParts.inKeyword, isNotNull);
    var iterable = forLoopParts.iterable as SimpleIdentifier;
    expect(iterable.name, 'list');
  }

  void test_mapLiteral_forIf() {
    var map = parseCollectionLiteral('{1:7, await for (y in list) if (c) 2:3}',
        inAsync: true) as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 7);

    var second = map.elements[1] as ForElement;
    expect(second.awaitKeyword, isNotNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    var forLoopParts = second.forLoopParts as ForEachPartsWithIdentifier;
    SimpleIdentifier forLoopVar = forLoopParts.identifier;
    expect(forLoopVar.name, 'y');
    expect(forLoopParts.inKeyword, isNotNull);
    var iterable = forLoopParts.iterable as SimpleIdentifier;
    expect(iterable.name, 'list');

    var body = second.body as IfElement;
    var condition = body.condition as SimpleIdentifier;
    expect(condition.name, 'c');
    var thenElement = body.thenElement as MapLiteralEntry;
    var thenValue = thenElement.value as IntegerLiteral;
    expect(thenValue.value, 3);
  }

  void test_mapLiteral_forSpread() {
    var map = parseCollectionLiteral('{1:7, for (x = 0; x < 10; ++x) ...{2:3}}')
        as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 7);

    var second = map.elements[1] as ForElement;
    expect(second.awaitKeyword, isNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    var forLoopParts = second.forLoopParts as ForPartsWithExpression;
    var forLoopInit = forLoopParts.initialization as AssignmentExpression;
    var forLoopVar = forLoopInit.leftHandSide as SimpleIdentifier;
    expect(forLoopVar.name, 'x');
    var condition = forLoopParts.condition as BinaryExpression;
    var rightOperand = condition.rightOperand as IntegerLiteral;
    expect(rightOperand.value, 10);
    var updater = forLoopParts.updaters[0] as PrefixExpression;
    var updaterOperand = updater.operand as SimpleIdentifier;
    expect(updaterOperand.name, 'x');
  }

  void test_mapLiteral_if() {
    var map = parseCollectionLiteral('{1:1, if (true) 2:4}') as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 1);

    var second = map.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as MapLiteralEntry;
    var thenElementValue = thenElement.value as IntegerLiteral;
    expect(thenElementValue.value, 4);
    expect(second.elseElement, isNull);
  }

  void test_mapLiteral_ifElse() {
    var map = parseCollectionLiteral('{1:1, if (true) 2:4 else 5:6}')
        as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 1);

    var second = map.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as MapLiteralEntry;
    var thenElementValue = thenElement.value as IntegerLiteral;
    expect(thenElementValue.value, 4);
    var elseElement = second.elseElement as MapLiteralEntry;
    var elseElementValue = elseElement.value as IntegerLiteral;
    expect(elseElementValue.value, 6);
  }

  void test_mapLiteral_ifElseFor() {
    var map =
        parseCollectionLiteral('{1:1, if (true) 2:4 else for (c in d) 5:6}')
            as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 1);

    var second = map.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as MapLiteralEntry;
    var thenElementValue = thenElement.value as IntegerLiteral;
    expect(thenElementValue.value, 4);

    var elseElement = second.elseElement as ForElement;
    var forLoopParts = elseElement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forLoopParts.identifier.name, 'c');

    var body = elseElement.body as MapLiteralEntry;
    var bodyValue = body.value as IntegerLiteral;
    expect(bodyValue.value, 6);
  }

  void test_mapLiteral_ifElseSpread() {
    var map = parseCollectionLiteral('{1:7, if (true) ...{2:4} else ...?{5:6}}')
        as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 7);

    var second = map.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as SpreadElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    var elseElement = second.elseElement as SpreadElement;
    expect(elseElement.spreadOperator.lexeme, '...?');
    var elseElementExpression = elseElement.expression as SetOrMapLiteral;
    expect(elseElementExpression.elements, hasLength(1));
    var entry = elseElementExpression.elements[0] as MapLiteralEntry;
    var entryValue = entry.value as IntegerLiteral;
    expect(entryValue.value, 6);
  }

  void test_mapLiteral_ifFor() {
    var map = parseCollectionLiteral('{1:1, if (true) for (a in b) 2:4}')
        as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 1);

    var second = map.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);

    var thenElement = second.thenElement as ForElement;
    var forLoopParts = thenElement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forLoopParts.identifier.name, 'a');

    var body = thenElement.body as MapLiteralEntry;
    var thenElementValue = body.value as IntegerLiteral;
    expect(thenElementValue.value, 4);
    expect(second.elseElement, isNull);
  }

  void test_mapLiteral_ifSpread() {
    SetOrMapLiteral map = parseCollectionLiteral('{1:1, if (true) ...{2:4}}');
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 1);

    var second = map.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as SpreadElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    expect(second.elseElement, isNull);
  }

  void test_mapLiteral_spread() {
    var map = parseCollectionLiteral('{1: 2, ...{3: 4}}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(2));

    var element = map.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spread2_typed() {
    var map = parseCollectionLiteral('<int, int>{1: 2, ...{3: 4}}')
        as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(2));

    var element = map.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spread_typed() {
    var map =
        parseCollectionLiteral('<int, int>{...{3: 4}}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(1));

    var element = map.elements[0] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spreadQ() {
    var map = parseCollectionLiteral('{1: 2, ...?{3: 4}}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(2));

    var element = map.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spreadQ2_typed() {
    var map = parseCollectionLiteral('<int, int>{1: 2, ...?{3: 4}}')
        as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(2));

    var element = map.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spreadQ_typed() {
    var map =
        parseCollectionLiteral('<int, int>{...?{3: 4}}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments.arguments, hasLength(2));
    expect(map.elements, hasLength(1));

    var element = map.elements[0] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setLiteral_if() {
    var setLiteral =
        parseCollectionLiteral('{1, if (true) 2}') as SetOrMapLiteral;
    expect(setLiteral.elements, hasLength(2));
    var first = setLiteral.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = setLiteral.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as IntegerLiteral;
    expect(thenElement.value, 2);
    expect(second.elseElement, isNull);
  }

  void test_setLiteral_ifElse() {
    var setLiteral =
        parseCollectionLiteral('{1, if (true) 2 else 5}') as SetOrMapLiteral;
    expect(setLiteral.elements, hasLength(2));
    var first = setLiteral.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = setLiteral.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as IntegerLiteral;
    expect(thenElement.value, 2);
    var elseElement = second.elseElement as IntegerLiteral;
    expect(elseElement.value, 5);
  }

  void test_setLiteral_ifElseSpread() {
    var setLiteral =
        parseCollectionLiteral('{1, if (true) ...{2} else ...?[5]}')
            as SetOrMapLiteral;
    expect(setLiteral.elements, hasLength(2));
    var first = setLiteral.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = setLiteral.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as SpreadElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    var theExpression = thenElement.expression as SetOrMapLiteral;
    expect(theExpression.elements, hasLength(1));
    var elseElement = second.elseElement as SpreadElement;
    expect(elseElement.spreadOperator.lexeme, '...?');
    var elseExpression = elseElement.expression as ListLiteral;
    expect(elseExpression.elements, hasLength(1));
  }

  void test_setLiteral_ifSpread() {
    var setLiteral =
        parseCollectionLiteral('{1, if (true) ...[2]}') as SetOrMapLiteral;
    expect(setLiteral.elements, hasLength(2));
    var first = setLiteral.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = setLiteral.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as SpreadElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    expect(second.elseElement, isNull);
  }

  void test_setLiteral_spread2() {
    var set = parseCollectionLiteral('{3, ...[4]}') as SetOrMapLiteral;
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements, hasLength(2));
    var value = set.elements[0] as IntegerLiteral;
    expect(value.value, 3);

    var element = set.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as ListLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setLiteral_spread2Q() {
    var set = parseCollectionLiteral('{3, ...?[4]}') as SetOrMapLiteral;
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements, hasLength(2));
    var value = set.elements[0] as IntegerLiteral;
    expect(value.value, 3);

    var element = set.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as ListLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setLiteral_spread_typed() {
    var set = parseCollectionLiteral('<int>{...[3]}') as SetOrMapLiteral;
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNotNull);
    expect(set.elements, hasLength(1));

    var element = set.elements[0] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as ListLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setLiteral_spreadQ_typed() {
    var set = parseCollectionLiteral('<int>{...?[3]}') as SetOrMapLiteral;
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNotNull);
    expect(set.elements, hasLength(1));

    var element = set.elements[0] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as ListLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setOrMapLiteral_spread() {
    var map = parseCollectionLiteral('{...{3: 4}}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(1));

    var element = map.elements[0] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setOrMapLiteral_spreadQ() {
    var map = parseCollectionLiteral('{...?{3: 4}}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(1));

    var element = map.elements[0] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
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
          codes: codes,
          errors: errors,
          featureSet: featureSet ?? FeatureSet.latestLanguageVersion());

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
    parseCompilationUnit(r'+t{{r?this}}', errors: [
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
    CompilationUnit unit = parseCompilationUnit('main() { a?[7]; }');
    FunctionDeclaration method = unit.declarations[0];
    BlockFunctionBody body = method.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    IndexExpression expression = statement.expression;
    expect(expression.question, isNotNull);
    expect(expression.leftBracket.lexeme, '[');
    expect(expression.rightBracket.lexeme, ']');
    expect(expression.leftBracket.endGroup, expression.rightBracket);
  }

  void test_indexed_nullAware_optOut() {
    CompilationUnit unit = parseCompilationUnit('''
// @dart = 2.2
main() { a?[7]; }''',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 25, 1)]);
    FunctionDeclaration method = unit.declarations[0];
    BlockFunctionBody body = method.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    IndexExpressionImpl expression = statement.expression;
    expect(expression.target.toSource(), 'a');
    expect(expression.question, isNotNull);
    expect(expression.leftBracket.lexeme, '[');
    expect(expression.rightBracket.lexeme, ']');
    expect(expression.leftBracket.endGroup, expression.rightBracket);
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
    assertErrors(errors: [
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 5, 1)
    ]);
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
    assertErrors(errors: [
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 5, 1)
    ]);
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

  void test_parseVariableDeclaration_late_var_init() {
    var statement = parseStatement('late var a = 0;', featureSet: nonNullable)
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

  void test_parseLocalVariable_external() {
    parseStatement('external int i;', featureSet: nonNullable);
    assertErrors(errors: [
      expectedError(ParserErrorCode.EXTRANEOUS_MODIFIER, 0, 8),
    ]);
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

  void test_parseTopLevelVariable_external() {
    var unit = parseCompilationUnit('external int i;', featureSet: nonNullable);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    expect(declaration.externalKeyword, isNotNull);
  }

  void test_parseTopLevelVariable_external_late() {
    var unit = parseCompilationUnit('external late int? i;',
        featureSet: nonNullable,
        errors: [
          expectedError(ParserErrorCode.EXTERNAL_LATE_FIELD, 0, 8),
        ]);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    expect(declaration.externalKeyword, isNotNull);
  }

  void test_parseTopLevelVariable_external_late_final() {
    var unit = parseCompilationUnit('external late final int? i;',
        featureSet: nonNullable,
        errors: [
          expectedError(ParserErrorCode.EXTERNAL_LATE_FIELD, 0, 8),
        ]);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    expect(declaration.externalKeyword, isNotNull);
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

  void test_parseTopLevelVariable_non_external() {
    var unit = parseCompilationUnit('int i;', featureSet: nonNullable);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    expect(declaration.externalKeyword, isNull);
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
          expectedError(
              ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD, 7, 2),
          expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 3),
        ],
        featureSet: FeatureSet.forTesting(sdkVersion: '2.5.0'));
  }

  void test_function_enabled() {
    parseCompilationUnit('void A(in int value) {}', errors: [
      expectedError(ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD, 7, 2),
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
