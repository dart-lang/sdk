// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_test_base.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternsTest);
  });
}

@reflectiveTest
class PatternsTest extends FastaParserTestCase {
  final FeatureSet _enabledFeatureSet = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: ExperimentStatus.currentVersion,
    flags: [EnableString.patterns],
  );

  late FindNode findNode;

  test_cast_insideCase() {
    _parse('''
test(dynamic x) {
  const y = 1;
  switch (x) {
    case y as int:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y as int');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<ConstantPattern>());
    expect(castPattern.type.toString(), 'int');
  }

  test_cast_insideExtractor_explicitlyNamed() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(f: 1 as int):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C(f: 1 as int)");
    var extractorPattern = switchPatternCase.pattern as ExtractorPattern;
    expect(extractorPattern.fields[0].pattern, TypeMatcher<CastPattern>());
  }

  test_cast_insideExtractor_implicitlyNamed() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(: var f as int):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C(: var f as int)");
    var extractorPattern = switchPatternCase.pattern as ExtractorPattern;
    expect(extractorPattern.fields[0].pattern, TypeMatcher<CastPattern>());
  }

  test_cast_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case var y as int) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    expect(caseClause.pattern, TypeMatcher<CastPattern>());
  }

  test_cast_insideList() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case [1 as int]:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('[1 as int]');
    var listPattern = switchPatternCase.pattern as ListPattern;
    expect(listPattern.elements[0], TypeMatcher<CastPattern>());
  }

  test_cast_insideLogicalAnd_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int? _ as double? & Object? _:
      break;
  }
}
''');
    var switchPatternCase =
        findNode.switchPatternCase('int? _ as double? & Object? _');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.operator.lexeme, '&');
    expect(binaryPattern.leftOperand, TypeMatcher<CastPattern>());
    expect(binaryPattern.rightOperand, TypeMatcher<VariablePattern>());
  }

  test_cast_insideLogicalAnd_rhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int? _ & double? _ as Object?:
      break;
  }
}
''');
    var switchPatternCase =
        findNode.switchPatternCase('int? _ & double? _ as Object?');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.operator.lexeme, '&');
    expect(binaryPattern.leftOperand, TypeMatcher<VariablePattern>());
    expect(binaryPattern.rightOperand, TypeMatcher<CastPattern>());
  }

  test_cast_insideLogicalOr_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int? _ as double? | Object? _:
      break;
  }
}
''');
    var switchPatternCase =
        findNode.switchPatternCase('int? _ as double? | Object? _');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.leftOperand, TypeMatcher<CastPattern>());
    expect(binaryPattern.rightOperand, TypeMatcher<VariablePattern>());
  }

  test_cast_insideLogicalOr_rhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int? _ | double? _ as Object?:
      break;
  }
}
''');
    var switchPatternCase =
        findNode.switchPatternCase('int? _ | double? _ as Object?');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.leftOperand, TypeMatcher<VariablePattern>());
    expect(binaryPattern.rightOperand, TypeMatcher<CastPattern>());
  }

  test_cast_insideMap() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case {'a': 1 as int}:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("{'a': 1 as int}");
    var mapPattern = switchPatternCase.pattern as MapPattern;
    expect(mapPattern.entries[0].value, TypeMatcher<CastPattern>());
  }

  test_cast_insideParenthesized() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1 as int):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('(1 as int)');
    var parenthesizedPattern =
        switchPatternCase.pattern as ParenthesizedPattern;
    expect(parenthesizedPattern.pattern, TypeMatcher<CastPattern>());
  }

  test_cast_insideRecord_explicitlyNamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (n: 1 as int, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(n: 1 as int, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<CastPattern>());
  }

  test_cast_insideRecord_implicitlyNamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (: var n as int, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(: var n as int, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<CastPattern>());
  }

  test_cast_insideRecord_unnamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1 as int, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(1 as int, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<CastPattern>());
  }

  test_constant_identifier_unprefixed_insideCase() {
    _parse('''
test(dynamic x) {
  const y = 1;
  switch (x) {
    case y:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y:');
    var constantPattern = switchPatternCase.pattern as ConstantPattern;
    expect(constantPattern.expression.toString(), 'y');
  }

  test_constant_identifier_unprefixed_insideCast() {
    _parse('''
test(dynamic x) {
  const y = 1;
  switch (x) {
    case y as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<ConstantPattern>());
    expect(castPattern.type.toString(), 'Object');
  }

  test_constant_identifier_unprefixed_insideIfCase() {
    _parse('''
test(dynamic x) {
  const y = 1;
  if (x case y) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    var constantPattern = caseClause.pattern as ConstantPattern;
    expect(constantPattern.expression.toString(), 'y');
  }

  test_constant_identifier_unprefixed_insideNullAssert() {
    _parse('''
test(dynamic x) {
  const y = 1;
  switch (x) {
    case y!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_constant_identifier_unprefixed_insideNullCheck() {
    _parse('''
test(dynamic x) {
  const y = 1;
  switch (x) {
    case y?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_errorRecovery_afterQuestionSuffixInExpression() {
    // Based on co19 test `Language/Expressions/Conditional/syntax_t06.dart`.
    // Even though we now support suffix `?` in patterns, we need to make sure
    // that a suffix `?` in an expression still causes the appropriate syntax
    // error.
    _parse('''
f() {
  try {
    true ?  : 2;
  } catch (e) {}
}
''', errors: [
      error(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
    ]);
  }

  test_extractor_pattern_with_type_args() {
    _parse('''
class C<T> {}
test(dynamic x) {
  switch (x) {
    case C<int>():
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C<int>()");
    var extractorPattern = switchPatternCase.pattern as ExtractorPattern;
    expect(extractorPattern.typeName.toString(), 'C');
    expect(extractorPattern.typeArguments.toString(), '<int>');
  }

  test_extractor_prefixed_withTypeArgs_insideCase() {
    _parse('''
import 'dart:async' as async;

test(dynamic x) {
  switch (x) {
    case async.Future<int>():
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("async.Future<int>()");
    var extractorPattern = switchPatternCase.pattern as ExtractorPattern;
    expect(extractorPattern.typeName.toString(), 'async.Future');
    expect(extractorPattern.typeArguments.toString(), '<int>');
  }

  test_extractor_prefixed_withTypeArgs_insideCast() {
    _parse('''
import 'dart:async' as async;

test(dynamic x) {
  switch (x) {
    case async.Future<int>() as Object:
      break;
  }
}
''');
    var switchPatternCase =
        findNode.switchPatternCase("async.Future<int>() as Object");
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<ExtractorPattern>());
    expect(castPattern.type.toString(), 'Object');
  }

  test_extractor_prefixed_withTypeArgs_insideNullAssert() {
    _parse('''
import 'dart:async' as async;

test(dynamic x) {
  switch (x) {
    case async.Future<int>()!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("async.Future<int>()!");
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ExtractorPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_extractor_prefixed_withTypeArgs_insideNullCheck() {
    _parse('''
import 'dart:async' as async;

test(dynamic x) {
  switch (x) {
    case async.Future<int>()?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("async.Future<int>()?");
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ExtractorPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_extractor_unprefixed_withoutTypeArgs_insideCast() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(f: 1) as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C(f: 1) as Object");
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<ExtractorPattern>());
    expect(castPattern.type.toString(), 'Object');
  }

  test_extractor_unprefixed_withoutTypeArgs_insideNullAssert() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(f: 1)!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C(f: 1)!");
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ExtractorPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_extractor_unprefixed_withoutTypeArgs_insideNullCheck() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(f: 1)?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C(f: 1)?");
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ExtractorPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_extractor_unprefixed_withTypeArgs_insideNullAssert() {
    _parse('''
class C<T> {
  T? f;
}
test(dynamic x) {
  switch (x) {
    case C<int>(f: 1)!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C<int>(f: 1)!");
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ExtractorPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_list_insideCase_typed_nonEmpty() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case <int>[1, 2]:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('[1, 2]');
    var listPattern = switchPatternCase.pattern as ListPattern;
    expect(listPattern.typeArguments.toString(), '<int>');
    expect(listPattern.leftBracket.lexeme, '[');
    expect(listPattern.elements, hasLength(2));
    expect(listPattern.elements[0].toString(), '1');
    expect(listPattern.elements[1].toString(), '2');
    expect(listPattern.rightBracket.lexeme, ']');
  }

  test_list_insideCase_untyped_empty() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case []:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('[]');
    var listPattern = switchPatternCase.pattern as ListPattern;
    expect(listPattern.typeArguments, isNull);
    expect(listPattern.leftBracket.lexeme, '[');
    expect(listPattern.elements, isEmpty);
    expect(listPattern.rightBracket.lexeme, ']');
  }

  test_list_insideCase_untyped_emptyWithWhitespace() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case [ ]:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('[ ]');
    var listPattern = switchPatternCase.pattern as ListPattern;
    expect(listPattern.typeArguments, isNull);
    expect(listPattern.leftBracket.lexeme, '[');
    expect(listPattern.elements, isEmpty);
    expect(listPattern.rightBracket.lexeme, ']');
  }

  test_list_insideCase_untyped_nonEmpty() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case [1, 2]:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('[1, 2]');
    var listPattern = switchPatternCase.pattern as ListPattern;
    expect(listPattern.typeArguments, isNull);
    expect(listPattern.leftBracket.lexeme, '[');
    expect(listPattern.elements, hasLength(2));
    expect(listPattern.elements[0].toString(), '1');
    expect(listPattern.elements[1].toString(), '2');
    expect(listPattern.rightBracket.lexeme, ']');
  }

  test_list_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case [1] as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('[1] as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<ListPattern>());
    expect(castPattern.type.toString(), 'Object');
  }

  test_list_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case [1]!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('[1]!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ListPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_list_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case [1]?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('[1]?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ListPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_literal_boolean_insideCase() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case true:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('true');
    var constantPattern = switchPatternCase.pattern as ConstantPattern;
    expect(constantPattern.expression, TypeMatcher<BooleanLiteral>());
  }

  test_literal_boolean_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case true as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('true as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<ConstantPattern>());
    expect(castPattern.type.toString(), 'Object');
  }

  test_literal_boolean_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case true) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    var constantPattern = caseClause.pattern as ConstantPattern;
    expect(constantPattern.expression, TypeMatcher<BooleanLiteral>());
  }

  test_literal_boolean_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case true!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('true!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_literal_boolean_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case true?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('true?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_literal_double_insideCase() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1.0:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1.0');
    var constantPattern = switchPatternCase.pattern as ConstantPattern;
    expect(constantPattern.expression, TypeMatcher<DoubleLiteral>());
  }

  test_literal_double_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1.0 as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1.0 as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<ConstantPattern>());
    expect(castPattern.type.toString(), 'Object');
  }

  test_literal_double_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case 1.0) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    var constantPattern = caseClause.pattern as ConstantPattern;
    expect(constantPattern.expression, TypeMatcher<DoubleLiteral>());
  }

  test_literal_double_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1.0!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1.0!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_literal_double_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1.0?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1.0?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_literal_integer_insideCase() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1');
    var constantPattern = switchPatternCase.pattern as ConstantPattern;
    expect(constantPattern.expression, TypeMatcher<IntegerLiteral>());
  }

  test_literal_integer_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1 as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1 as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<ConstantPattern>());
    expect(castPattern.type.toString(), 'Object');
  }

  test_literal_integer_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case 1) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    var constantPattern = caseClause.pattern as ConstantPattern;
    expect(constantPattern.expression, TypeMatcher<IntegerLiteral>());
  }

  test_literal_integer_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_literal_integer_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_literal_null_insideCase() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case null:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('null');
    var constantPattern = switchPatternCase.pattern as ConstantPattern;
    expect(constantPattern.expression, TypeMatcher<NullLiteral>());
  }

  test_literal_null_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case null as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('null as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<ConstantPattern>());
    expect(castPattern.type.toString(), 'Object');
  }

  test_literal_null_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case null) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    var constantPattern = caseClause.pattern as ConstantPattern;
    expect(constantPattern.expression, TypeMatcher<NullLiteral>());
  }

  test_literal_null_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case null!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('null!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_literal_null_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case null?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('null?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_literal_string_insideCase() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case "x":
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('"x"');
    var constantPattern = switchPatternCase.pattern as ConstantPattern;
    expect(constantPattern.expression, TypeMatcher<StringLiteral>());
  }

  test_literal_string_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case "x" as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('"x" as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<ConstantPattern>());
    expect(castPattern.type.toString(), 'Object');
  }

  test_literal_string_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case "x") {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    var constantPattern = caseClause.pattern as ConstantPattern;
    expect(constantPattern.expression, TypeMatcher<StringLiteral>());
  }

  test_literal_string_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case "x"!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('"x"!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_literal_string_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case "x"?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('"x"?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_logicalAnd_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case int? _ & double? _) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    var binaryPattern = caseClause.pattern as BinaryPattern;
    expect(binaryPattern.operator.lexeme, '&');
  }

  test_logicalAnd_insideLogicalAnd_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int? _ & double? _ & Object? _:
      break;
  }
}
''');
    var switchPatternCase =
        findNode.switchPatternCase('int? _ & double? _ & Object? _');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.operator.lexeme, '&');
    expect(binaryPattern.leftOperand, TypeMatcher<BinaryPattern>());
    expect(binaryPattern.rightOperand, TypeMatcher<VariablePattern>());
  }

  test_logicalAnd_insideLogicalOr_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int? _ & double? _ | Object? _:
      break;
  }
}
''');
    var switchPatternCase =
        findNode.switchPatternCase('int? _ & double? _ | Object? _');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.leftOperand, TypeMatcher<BinaryPattern>());
    expect(binaryPattern.rightOperand, TypeMatcher<VariablePattern>());
  }

  test_logicalAnd_insideLogicalOr_rhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int? _ | double? _ & Object? _:
      break;
  }
}
''');
    var switchPatternCase =
        findNode.switchPatternCase('int? _ | double? _ & Object? _');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.leftOperand, TypeMatcher<VariablePattern>());
    expect(binaryPattern.rightOperand, TypeMatcher<BinaryPattern>());
  }

  test_logicalOr_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case int? _ | double? _) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    var binaryPattern = caseClause.pattern as BinaryPattern;
    expect(binaryPattern.operator.lexeme, '|');
  }

  test_logicalOr_insideLogicalOr_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int? _ | double? _ | Object? _:
      break;
  }
}
''');
    var switchPatternCase =
        findNode.switchPatternCase('int? _ | double? _ | Object? _');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.leftOperand, TypeMatcher<BinaryPattern>());
    expect(binaryPattern.rightOperand, TypeMatcher<VariablePattern>());
  }

  test_map_insideCase_typed_nonEmpty() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case <String, int>{'a': 1, 'b': 2}:
      break;
  }
}
''');
    var switchPatternCase =
        findNode.switchPatternCase("<String, int>{'a': 1, 'b': 2}");
    var mapPattern = switchPatternCase.pattern as MapPattern;
    expect(mapPattern.typeArguments.toString(), '<String, int>');
    expect(mapPattern.leftBracket.lexeme, '{');
    expect(mapPattern.entries, hasLength(2));
    expect(mapPattern.entries[0].key.toString(), "'a'");
    expect(mapPattern.entries[0].separator.lexeme, ':');
    expect(mapPattern.entries[0].value.toString(), '1');
    expect(mapPattern.entries[1].key.toString(), "'b'");
    expect(mapPattern.entries[1].separator.lexeme, ':');
    expect(mapPattern.entries[1].value.toString(), '2');
    expect(mapPattern.rightBracket.lexeme, '}');
  }

  test_map_insideCase_untyped_empty() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case {}:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("{}");
    var mapPattern = switchPatternCase.pattern as MapPattern;
    expect(mapPattern.typeArguments, isNull);
    expect(mapPattern.leftBracket.lexeme, '{');
    expect(mapPattern.entries, isEmpty);
    expect(mapPattern.rightBracket.lexeme, '}');
  }

  test_map_insideCase_untyped_nonEmpty() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case {'a': 1, 'b': 2}:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("{'a': 1, 'b': 2}");
    var mapPattern = switchPatternCase.pattern as MapPattern;
    expect(mapPattern.typeArguments, isNull);
    expect(mapPattern.leftBracket.lexeme, '{');
    expect(mapPattern.entries, hasLength(2));
    expect(mapPattern.entries[0].key.toString(), "'a'");
    expect(mapPattern.entries[0].separator.lexeme, ':');
    expect(mapPattern.entries[0].value.toString(), '1');
    expect(mapPattern.entries[1].key.toString(), "'b'");
    expect(mapPattern.entries[1].separator.lexeme, ':');
    expect(mapPattern.entries[1].value.toString(), '2');
    expect(mapPattern.rightBracket.lexeme, '}');
  }

  test_map_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case {'a': 1} as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("{'a': 1} as Object");
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<MapPattern>());
    expect(castPattern.type.toString(), 'Object');
  }

  test_map_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case {'a': 1}!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("{'a': 1}!");
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<MapPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_map_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case {'a': 1}?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("{'a': 1}?");
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<MapPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_nullAssert_insideCase() {
    _parse('''
test(dynamic x) {
  const y = 1;
  switch (x) {
    case y!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_nullAssert_insideExtractor_explicitlyNamed() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(f: 1!):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C(f: 1!)");
    var extractorPattern = switchPatternCase.pattern as ExtractorPattern;
    expect(extractorPattern.fields[0].pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullAssert_insideExtractor_implicitlyNamed() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(: var f!):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C(: var f!)");
    var extractorPattern = switchPatternCase.pattern as ExtractorPattern;
    expect(extractorPattern.fields[0].pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullAssert_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case var y!) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    expect(caseClause.pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullAssert_insideList() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case [1!]:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('[1!]');
    var listPattern = switchPatternCase.pattern as ListPattern;
    expect(listPattern.elements[0], TypeMatcher<PostfixPattern>());
  }

  test_nullAssert_insideLogicalAnd_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1! & 2:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1! & 2');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<PostfixPattern>());
    expect(binaryPattern.operator.lexeme, '&');
    expect(binaryPattern.rightOperand, TypeMatcher<ConstantPattern>());
  }

  test_nullAssert_insideLogicalAnd_rhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1 & 2!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1 & 2!');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<ConstantPattern>());
    expect(binaryPattern.operator.lexeme, '&');
    expect(binaryPattern.rightOperand, TypeMatcher<PostfixPattern>());
  }

  test_nullAssert_insideLogicalOr_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1! | 2:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1! | 2');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<PostfixPattern>());
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.rightOperand, TypeMatcher<ConstantPattern>());
  }

  test_nullAssert_insideLogicalOr_rhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1 | 2!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1 | 2!');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<ConstantPattern>());
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.rightOperand, TypeMatcher<PostfixPattern>());
  }

  test_nullAssert_insideMap() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case {'a': 1!}:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("{'a': 1!}");
    var mapPattern = switchPatternCase.pattern as MapPattern;
    expect(mapPattern.entries[0].value, TypeMatcher<PostfixPattern>());
  }

  test_nullAssert_insideParenthesized() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1!):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('(1!)');
    var parenthesizedPattern =
        switchPatternCase.pattern as ParenthesizedPattern;
    expect(parenthesizedPattern.pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullAssert_insideRecord_explicitlyNamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (n: 1!, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(n: 1!, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullAssert_insideRecord_implicitlyNamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (: var n!, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(: var n!, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullAssert_insideRecord_unnamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1!, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(1!, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullCheck_insideCase() {
    _parse('''
test(dynamic x) {
  const y = 1;
  switch (x) {
    case y?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ConstantPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_nullCheck_insideExtractor_explicitlyNamed() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(f: 1?):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C(f: 1?)");
    var extractorPattern = switchPatternCase.pattern as ExtractorPattern;
    expect(extractorPattern.fields[0].pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullCheck_insideExtractor_implicitlyNamed() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(: var f?):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C(: var f?)");
    var extractorPattern = switchPatternCase.pattern as ExtractorPattern;
    expect(extractorPattern.fields[0].pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullCheck_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case var y?) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    expect(caseClause.pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullCheck_insideList() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case [1?]:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('[1?]');
    var listPattern = switchPatternCase.pattern as ListPattern;
    expect(listPattern.elements[0], TypeMatcher<PostfixPattern>());
  }

  test_nullCheck_insideLogicalAnd_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1? & 2:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1? & 2');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<PostfixPattern>());
    expect(binaryPattern.operator.lexeme, '&');
    expect(binaryPattern.rightOperand, TypeMatcher<ConstantPattern>());
  }

  test_nullCheck_insideLogicalAnd_rhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1 & 2?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1 & 2?');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<ConstantPattern>());
    expect(binaryPattern.operator.lexeme, '&');
    expect(binaryPattern.rightOperand, TypeMatcher<PostfixPattern>());
  }

  test_nullCheck_insideLogicalOr_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1? | 2:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1? | 2');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<PostfixPattern>());
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.rightOperand, TypeMatcher<ConstantPattern>());
  }

  test_nullCheck_insideLogicalOr_rhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1 | 2?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1 | 2?');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<ConstantPattern>());
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.rightOperand, TypeMatcher<PostfixPattern>());
  }

  test_nullCheck_insideMap() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case {'a': 1?}:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("{'a': 1?}");
    var mapPattern = switchPatternCase.pattern as MapPattern;
    expect(mapPattern.entries[0].value, TypeMatcher<PostfixPattern>());
  }

  test_nullCheck_insideParenthesized() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1?):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('(1?)');
    var parenthesizedPattern =
        switchPatternCase.pattern as ParenthesizedPattern;
    expect(parenthesizedPattern.pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullCheck_insideRecord_explicitlyNamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (n: 1?, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(n: 1?, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullCheck_insideRecord_implicitlyNamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (: var n?, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(: var n?, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<PostfixPattern>());
  }

  test_nullCheck_insideRecord_unnamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1?, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(1?, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<PostfixPattern>());
  }

  test_parenthesized_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1) as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('(1) as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<ParenthesizedPattern>());
    expect(castPattern.type.toString(), 'Object');
  }

  test_parenthesized_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1)!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('(1)!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ParenthesizedPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_parenthesized_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1)?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('(1)?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<ParenthesizedPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_record_insideCase_empty() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case ():
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("()");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.leftParenthesis.lexeme, '(');
    expect(recordPattern.fields, isEmpty);
    expect(recordPattern.rightParenthesis.lexeme, ')');
  }

  test_record_insideCase_oneField() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1,):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(1,)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.leftParenthesis.lexeme, '(');
    expect(recordPattern.fields, hasLength(1));
    expect(recordPattern.fields[0].toString(), '1');
    expect(recordPattern.rightParenthesis.lexeme, ')');
  }

  test_record_insideCase_twoFIelds() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(1, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.leftParenthesis.lexeme, '(');
    expect(recordPattern.fields, hasLength(2));
    expect(recordPattern.fields[0].toString(), '1');
    expect(recordPattern.fields[1].toString(), '2');
    expect(recordPattern.rightParenthesis.lexeme, ')');
  }

  test_record_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1, 2) as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(1, 2) as Object");
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.pattern, TypeMatcher<RecordPattern>());
    expect(castPattern.type.toString(), 'Object');
  }

  test_record_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1, 2)!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(1, 2)!");
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<RecordPattern>());
    expect(postfixPattern.operator.lexeme, '!');
  }

  test_record_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (1, 2)?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(1, 2)?");
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operand, TypeMatcher<RecordPattern>());
    expect(postfixPattern.operator.lexeme, '?');
  }

  test_relational_insideCase_equal() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case == 1 << 1:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('== 1 << 1');
    var relationalPattern = switchPatternCase.pattern as RelationalPattern;
    expect(relationalPattern.operator.lexeme, '==');
    expect(relationalPattern.operand.toString(), '1 << 1');
  }

  test_relational_insideCase_greaterThan() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case > 1 << 1:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('> 1 << 1');
    var relationalPattern = switchPatternCase.pattern as RelationalPattern;
    expect(relationalPattern.operator.lexeme, '>');
    expect(relationalPattern.operand.toString(), '1 << 1');
  }

  test_relational_insideCase_greaterThanOrEqual() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case >= 1 << 1:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('>= 1 << 1');
    var relationalPattern = switchPatternCase.pattern as RelationalPattern;
    expect(relationalPattern.operator.lexeme, '>=');
    expect(relationalPattern.operand.toString(), '1 << 1');
  }

  test_relational_insideCase_lessThan() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case < 1 << 1:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('< 1 << 1');
    var relationalPattern = switchPatternCase.pattern as RelationalPattern;
    expect(relationalPattern.operator.lexeme, '<');
    expect(relationalPattern.operand.toString(), '1 << 1');
  }

  test_relational_insideCase_lessThanOrEqual() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case <= 1 << 1:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('<= 1 << 1');
    var relationalPattern = switchPatternCase.pattern as RelationalPattern;
    expect(relationalPattern.operator.lexeme, '<=');
    expect(relationalPattern.operand.toString(), '1 << 1');
  }

  test_relational_insideCase_notEqual() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case != 1 << 1:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('!= 1 << 1');
    var relationalPattern = switchPatternCase.pattern as RelationalPattern;
    expect(relationalPattern.operator.lexeme, '!=');
    expect(relationalPattern.operand.toString(), '1 << 1');
  }

  test_relational_insideExtractor_explicitlyNamed() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(f: == 1):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C(f: == 1)");
    var extractorPattern = switchPatternCase.pattern as ExtractorPattern;
    expect(
        extractorPattern.fields[0].pattern, TypeMatcher<RelationalPattern>());
  }

  test_relational_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case == 1) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    expect(caseClause.pattern, TypeMatcher<RelationalPattern>());
  }

  test_relational_insideList() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case [== 1]:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('[== 1]');
    var listPattern = switchPatternCase.pattern as ListPattern;
    expect(listPattern.elements[0], TypeMatcher<RelationalPattern>());
  }

  test_relational_insideLogicalAnd_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case == 1 & 2:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('== 1 & 2');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<RelationalPattern>());
    expect(binaryPattern.operator.lexeme, '&');
    expect(binaryPattern.rightOperand, TypeMatcher<ConstantPattern>());
  }

  test_relational_insideLogicalAnd_rhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1 & == 2:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1 & == 2');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<ConstantPattern>());
    expect(binaryPattern.operator.lexeme, '&');
    expect(binaryPattern.rightOperand, TypeMatcher<RelationalPattern>());
  }

  test_relational_insideLogicalOr_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case == 1 | 2:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('== 1 | 2');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<RelationalPattern>());
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.rightOperand, TypeMatcher<ConstantPattern>());
  }

  test_relational_insideLogicalOr_rhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1 | == 2:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1 | == 2');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<ConstantPattern>());
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.rightOperand, TypeMatcher<RelationalPattern>());
  }

  test_relational_insideMap() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case {'a': == 1}:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("{'a': == 1}");
    var mapPattern = switchPatternCase.pattern as MapPattern;
    expect(mapPattern.entries[0].value, TypeMatcher<RelationalPattern>());
  }

  test_relational_insideParenthesized() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (== 1):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('(== 1)');
    var parenthesizedPattern =
        switchPatternCase.pattern as ParenthesizedPattern;
    expect(parenthesizedPattern.pattern, TypeMatcher<RelationalPattern>());
  }

  test_relational_insideRecord_explicitlyNamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (n: == 1, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(n: == 1, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<RelationalPattern>());
  }

  test_relational_insideRecord_unnamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (== 1, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(== 1, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<RelationalPattern>());
  }

  test_variable_final_typed_insideCase() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case final int y:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('final int y');
    var variablePattern = switchPatternCase.pattern as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'final');
    expect(variablePattern.type.toString(), 'int');
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_final_typed_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case final int y as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.type.toString(), 'Object');
    var variablePattern = castPattern.pattern as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'final');
    expect(variablePattern.type, same(findNode.typeAnnotation('int')));
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_final_typed_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case final int y) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    var variablePattern = caseClause.pattern as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'final');
    expect(variablePattern.type.toString(), 'int');
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_final_typed_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case final int y!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operator.lexeme, '!');
    var variablePattern = postfixPattern.operand as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'final');
    expect(variablePattern.type, same(findNode.typeAnnotation('int')));
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_final_typed_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case final int y?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operator.lexeme, '?');
    var variablePattern = postfixPattern.operand as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'final');
    expect(variablePattern.type, same(findNode.typeAnnotation('int')));
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_final_untyped_insideCase() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case final y:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('final y');
    var variablePattern = switchPatternCase.pattern as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'final');
    expect(variablePattern.type, null);
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_final_untyped_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case final y as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.type.toString(), 'Object');
    var variablePattern = castPattern.pattern as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'final');
    expect(variablePattern.type, null);
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_final_untyped_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case final y) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    var variablePattern = caseClause.pattern as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'final');
    expect(variablePattern.type, null);
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_final_untyped_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case final y!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operator.lexeme, '!');
    var variablePattern = postfixPattern.operand as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'final');
    expect(variablePattern.type, null);
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_final_untyped_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case final y?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operator.lexeme, '?');
    var variablePattern = postfixPattern.operand as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'final');
    expect(variablePattern.type, null);
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_typed_insideCase() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int y:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('int y');
    var variablePattern = switchPatternCase.pattern as VariablePattern;
    expect(variablePattern.keyword, null);
    expect(variablePattern.type.toString(), 'int');
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_typed_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int y as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.type.toString(), 'Object');
    var variablePattern = castPattern.pattern as VariablePattern;
    expect(variablePattern.keyword, null);
    expect(variablePattern.type, same(findNode.typeAnnotation('int')));
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_typed_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case int y) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    var variablePattern = caseClause.pattern as VariablePattern;
    expect(variablePattern.keyword, null);
    expect(variablePattern.type.toString(), 'int');
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_typed_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int y!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operator.lexeme, '!');
    var variablePattern = postfixPattern.operand as VariablePattern;
    expect(variablePattern.keyword, null);
    expect(variablePattern.type, same(findNode.typeAnnotation('int')));
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_typed_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int y?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operator.lexeme, '?');
    var variablePattern = postfixPattern.operand as VariablePattern;
    expect(variablePattern.keyword, null);
    expect(variablePattern.type, same(findNode.typeAnnotation('int')));
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_typedNamedAs_insideCase() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int as:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('int as');
    var variablePattern = switchPatternCase.pattern as VariablePattern;
    expect(variablePattern.keyword, isNull);
    expect(variablePattern.type.toString(), 'int');
    expect(variablePattern.name.lexeme, 'as');
  }

  test_variable_typedNamedAs_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int as as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('int as as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.type.toString(), 'Object');
    var variablePattern = castPattern.pattern as VariablePattern;
    expect(variablePattern.keyword, null);
    expect(variablePattern.type, same(findNode.typeAnnotation('int')));
    expect(variablePattern.name.lexeme, 'as');
  }

  test_variable_typedNamedAs_insideExtractor_explicitlyNamed() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(f: int as):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C(f: int as)");
    var extractorPattern = switchPatternCase.pattern as ExtractorPattern;
    expect(extractorPattern.fields[0].pattern, TypeMatcher<VariablePattern>());
  }

  test_variable_typedNamedAs_insideExtractor_implicitlyNamed() {
    _parse('''
class C {
  int? f;
}
test(dynamic x) {
  switch (x) {
    case C(: int as):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("C(: int as)");
    var extractorPattern = switchPatternCase.pattern as ExtractorPattern;
    expect(extractorPattern.fields[0].pattern, TypeMatcher<VariablePattern>());
  }

  test_variable_typedNamedAs_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case int as) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    expect(caseClause.pattern, TypeMatcher<VariablePattern>());
  }

  test_variable_typedNamedAs_insideList() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case [int as]:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('[int as]');
    var listPattern = switchPatternCase.pattern as ListPattern;
    expect(listPattern.elements[0], TypeMatcher<VariablePattern>());
  }

  test_variable_typedNamedAs_insideLogicalAnd_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int as & 2:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('int as & 2');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<VariablePattern>());
    expect(binaryPattern.operator.lexeme, '&');
    expect(binaryPattern.rightOperand, TypeMatcher<ConstantPattern>());
  }

  test_variable_typedNamedAs_insideLogicalAnd_rhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1 & int as:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1 & int as');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<ConstantPattern>());
    expect(binaryPattern.operator.lexeme, '&');
    expect(binaryPattern.rightOperand, TypeMatcher<VariablePattern>());
  }

  test_variable_typedNamedAs_insideLogicalOr_lhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int as | 2:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('int as | 2');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<VariablePattern>());
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.rightOperand, TypeMatcher<ConstantPattern>());
  }

  test_variable_typedNamedAs_insideLogicalOr_rhs() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case 1 | int as:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('1 | int as');
    var binaryPattern = switchPatternCase.pattern as BinaryPattern;
    expect(binaryPattern.leftOperand, TypeMatcher<ConstantPattern>());
    expect(binaryPattern.operator.lexeme, '|');
    expect(binaryPattern.rightOperand, TypeMatcher<VariablePattern>());
  }

  test_variable_typedNamedAs_insideMap() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case {'a': int as}:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("{'a': int as}");
    var mapPattern = switchPatternCase.pattern as MapPattern;
    expect(mapPattern.entries[0].value, TypeMatcher<VariablePattern>());
  }

  test_variable_typedNamedAs_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int as!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('int as!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operator.lexeme, '!');
    var variablePattern = postfixPattern.operand as VariablePattern;
    expect(variablePattern.keyword, null);
    expect(variablePattern.type, same(findNode.typeAnnotation('int')));
    expect(variablePattern.name.lexeme, 'as');
  }

  test_variable_typedNamedAs_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case int as?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('int as?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operator.lexeme, '?');
    var variablePattern = postfixPattern.operand as VariablePattern;
    expect(variablePattern.keyword, null);
    expect(variablePattern.type, same(findNode.typeAnnotation('int')));
    expect(variablePattern.name.lexeme, 'as');
  }

  test_variable_typedNamedAs_insideParenthesized() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (int as):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('(int as)');
    var parenthesizedPattern =
        switchPatternCase.pattern as ParenthesizedPattern;
    expect(parenthesizedPattern.pattern, TypeMatcher<VariablePattern>());
  }

  test_variable_typedNamedAs_insideRecord_explicitlyNamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (n: int as, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(n: int as, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<VariablePattern>());
  }

  test_variable_typedNamedAs_insideRecord_implicitlyNamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (: int as, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(: int as, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<VariablePattern>());
  }

  test_variable_typedNamedAs_insideRecord_unnamed() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case (int as, 2):
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase("(int as, 2)");
    var recordPattern = switchPatternCase.pattern as RecordPattern;
    expect(recordPattern.fields[0].pattern, TypeMatcher<VariablePattern>());
  }

  test_variable_var_insideCase() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case var y:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('var y');
    var variablePattern = switchPatternCase.pattern as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'var');
    expect(variablePattern.type, null);
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_var_insideCast() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case var y as Object:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y as Object');
    var castPattern = switchPatternCase.pattern as CastPattern;
    expect(castPattern.type.toString(), 'Object');
    var variablePattern = castPattern.pattern as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'var');
    expect(variablePattern.type, null);
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_var_insideIfCase() {
    _parse('''
test(dynamic x) {
  if (x case var y) {}
}
''');
    var ifStatement = findNode.ifStatement('x case');
    expect(ifStatement.condition, same(findNode.simple('x case')));
    var caseClause = ifStatement.caseClause!;
    expect(caseClause, same(findNode.caseClause('case')));
    var variablePattern = caseClause.pattern as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'var');
    expect(variablePattern.type, null);
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_var_insideNullAssert() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case var y!:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y!');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operator.lexeme, '!');
    var variablePattern = postfixPattern.operand as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'var');
    expect(variablePattern.type, null);
    expect(variablePattern.name.lexeme, 'y');
  }

  test_variable_var_insideNullCheck() {
    _parse('''
test(dynamic x) {
  switch (x) {
    case var y?:
      break;
  }
}
''');
    var switchPatternCase = findNode.switchPatternCase('y?');
    var postfixPattern = switchPatternCase.pattern as PostfixPattern;
    expect(postfixPattern.operator.lexeme, '?');
    var variablePattern = postfixPattern.operand as VariablePattern;
    expect(variablePattern.keyword!.lexeme, 'var');
    expect(variablePattern.type, null);
    expect(variablePattern.name.lexeme, 'y');
  }

  void _parse(String content, {List<ExpectedError>? errors}) {
    var unit = parseCompilationUnit(content,
        errors: errors, featureSet: _enabledFeatureSet);
    findNode = FindNode(content, unit);
  }
}
