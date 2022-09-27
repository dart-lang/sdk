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

  test_boolean_literal_inside_case() {
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

  test_boolean_literal_inside_cast() {
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

  test_boolean_literal_inside_if_case() {
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

  test_boolean_literal_inside_null_assert() {
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

  test_boolean_literal_inside_null_check() {
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

  test_cast_inside_case() {
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

  test_cast_inside_extractor_pattern() {
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

  test_cast_inside_extractor_pattern_implicitly_named() {
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

  test_cast_inside_if_case() {
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

  test_cast_inside_list_pattern() {
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

  test_cast_inside_logical_and_lhs() {
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

  test_cast_inside_logical_and_rhs() {
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

  test_cast_inside_logical_or_lhs() {
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

  test_cast_inside_logical_or_rhs() {
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

  test_cast_inside_map_pattern() {
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

  test_cast_inside_parenthesized_pattern() {
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

  test_cast_inside_record_pattern_implicitly_named() {
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

  test_cast_inside_record_pattern_named() {
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

  test_cast_inside_record_pattern_unnamed() {
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

  test_constant_identifier_inside_case() {
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

  test_constant_identifier_inside_cast() {
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

  test_constant_identifier_inside_if_case() {
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

  test_constant_identifier_inside_null_assert() {
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

  test_constant_identifier_inside_null_check() {
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

  test_double_literal_inside_case() {
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

  test_double_literal_inside_cast() {
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

  test_double_literal_inside_if_case() {
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

  test_double_literal_inside_null_assert() {
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

  test_double_literal_inside_null_check() {
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

  test_error_recovery_after_question_suffix_in_expression() {
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

  test_extractor_pattern_inside_cast() {
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

  test_extractor_pattern_inside_null_assert() {
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

  test_extractor_pattern_inside_null_check() {
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

  test_extractor_pattern_with_type_args_inside_null_assert() {
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

  test_final_variable_inside_case() {
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

  test_final_variable_inside_cast() {
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

  test_final_variable_inside_if_case() {
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

  test_final_variable_inside_null_assert() {
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

  test_final_variable_inside_null_check() {
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

  test_integer_literal_inside_case() {
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

  test_integer_literal_inside_cast() {
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

  test_integer_literal_inside_if_case() {
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

  test_integer_literal_inside_null_assert() {
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

  test_integer_literal_inside_null_check() {
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

  test_list_pattern_inside_case() {
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

  test_list_pattern_inside_case_empty() {
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

  test_list_pattern_inside_case_empty_whitespace() {
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

  test_list_pattern_inside_case_with_type_arguments() {
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

  test_list_pattern_inside_cast() {
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

  test_list_pattern_inside_null_assert() {
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

  test_list_pattern_inside_null_check() {
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

  test_logical_and_inside_if_case() {
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

  test_logical_and_inside_logical_and_lhs() {
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

  test_logical_and_inside_logical_or_lhs() {
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

  test_logical_and_inside_logical_or_rhs() {
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

  test_logical_or_inside_if_case() {
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

  test_logical_or_inside_logical_or_lhs() {
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

  test_map_pattern_inside_case() {
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

  test_map_pattern_inside_case_empty() {
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

  test_map_pattern_inside_case_with_type_arguments() {
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

  test_map_pattern_inside_cast() {
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

  test_map_pattern_inside_null_assert() {
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

  test_map_pattern_inside_null_check() {
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

  test_null_assert_inside_case() {
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

  test_null_assert_inside_extractor_pattern() {
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

  test_null_assert_inside_extractor_pattern_implicitly_named() {
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

  test_null_assert_inside_if_case() {
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

  test_null_assert_inside_list_pattern() {
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

  test_null_assert_inside_logical_and_lhs() {
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

  test_null_assert_inside_logical_and_rhs() {
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

  test_null_assert_inside_logical_or_lhs() {
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

  test_null_assert_inside_logical_or_rhs() {
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

  test_null_assert_inside_map_pattern() {
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

  test_null_assert_inside_parenthesized_pattern() {
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

  test_null_assert_inside_record_pattern_implicitly_named() {
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

  test_null_assert_inside_record_pattern_named() {
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

  test_null_assert_inside_record_pattern_unnamed() {
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

  test_null_check_inside_case() {
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

  test_null_check_inside_extractor_pattern() {
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

  test_null_check_inside_extractor_pattern_implicitly_named() {
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

  test_null_check_inside_if_case() {
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

  test_null_check_inside_list_pattern() {
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

  test_null_check_inside_logical_and_lhs() {
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

  test_null_check_inside_logical_and_rhs() {
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

  test_null_check_inside_logical_or_lhs() {
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

  test_null_check_inside_logical_or_rhs() {
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

  test_null_check_inside_map_pattern() {
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

  test_null_check_inside_parenthesized_pattern() {
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

  test_null_check_inside_record_pattern_implicitly_named() {
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

  test_null_check_inside_record_pattern_named() {
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

  test_null_check_inside_record_pattern_unnamed() {
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

  test_null_literal_inside_case() {
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

  test_null_literal_inside_cast() {
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

  test_null_literal_inside_if_case() {
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

  test_null_literal_inside_null_assert() {
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

  test_null_literal_inside_null_check() {
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

  test_parenthesized_pattern_inside_cast() {
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

  test_parenthesized_pattern_inside_null_assert() {
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

  test_parenthesized_pattern_inside_null_check() {
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

  test_prefixed_extractor_pattern_with_type_args() {
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

  test_prefixed_extractor_pattern_with_type_args_inside_cast() {
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

  test_prefixed_extractor_pattern_with_type_args_inside_null_assert() {
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

  test_prefixed_extractor_pattern_with_type_args_inside_null_check() {
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

  test_record_pattern_inside_case() {
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

  test_record_pattern_inside_case_empty() {
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

  test_record_pattern_inside_case_singleton() {
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

  test_record_pattern_inside_cast() {
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

  test_record_pattern_inside_null_assert() {
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

  test_record_pattern_inside_null_check() {
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

  test_relational_inside_case_equal() {
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

  test_relational_inside_case_greater_than() {
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

  test_relational_inside_case_greater_than_or_equal() {
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

  test_relational_inside_case_less_than() {
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

  test_relational_inside_case_less_than_or_equal() {
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

  test_relational_inside_case_not_equal() {
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

  test_relational_inside_extractor_pattern() {
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

  test_relational_inside_if_case() {
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

  test_relational_inside_list_pattern() {
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

  test_relational_inside_logical_and_lhs() {
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

  test_relational_inside_logical_and_rhs() {
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

  test_relational_inside_logical_or_lhs() {
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

  test_relational_inside_logical_or_rhs() {
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

  test_relational_inside_map_pattern() {
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

  test_relational_inside_parenthesized_pattern() {
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

  test_relational_inside_record_pattern_named() {
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

  test_relational_inside_record_pattern_unnamed() {
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

  test_string_literal_inside_case() {
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

  test_string_literal_inside_cast() {
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

  test_string_literal_inside_if_case() {
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

  test_string_literal_inside_null_assert() {
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

  test_string_literal_inside_null_check() {
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

  test_typed_final_variable_inside_case() {
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

  test_typed_final_variable_inside_cast() {
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

  test_typed_final_variable_inside_if_case() {
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

  test_typed_final_variable_inside_null_assert() {
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

  test_typed_final_variable_inside_null_check() {
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

  test_typed_variable_inside_case() {
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

  test_typed_variable_inside_cast() {
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

  test_typed_variable_inside_if_case() {
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

  test_typed_variable_inside_null_assert() {
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

  test_typed_variable_inside_null_check() {
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

  test_typed_variable_named_as_inside_case() {
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

  test_typed_variable_named_as_inside_cast() {
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

  test_typed_variable_named_as_inside_extractor_pattern() {
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

  test_typed_variable_named_as_inside_extractor_pattern_implicitly_named() {
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

  test_typed_variable_named_as_inside_if_case() {
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

  test_typed_variable_named_as_inside_list_pattern() {
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

  test_typed_variable_named_as_inside_logical_and_lhs() {
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

  test_typed_variable_named_as_inside_logical_and_rhs() {
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

  test_typed_variable_named_as_inside_logical_or_lhs() {
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

  test_typed_variable_named_as_inside_logical_or_rhs() {
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

  test_typed_variable_named_as_inside_map_pattern() {
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

  test_typed_variable_named_as_inside_null_assert() {
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

  test_typed_variable_named_as_inside_null_check() {
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

  test_typed_variable_named_as_inside_parenthesized_pattern() {
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

  test_typed_variable_named_as_inside_record_pattern_implicitly_named() {
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

  test_typed_variable_named_as_inside_record_pattern_named() {
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

  test_typed_variable_named_as_inside_record_pattern_unnamed() {
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

  test_var_variable_inside_case() {
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

  test_var_variable_inside_cast() {
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

  test_var_variable_inside_if_case() {
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

  test_var_variable_inside_null_assert() {
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

  test_var_variable_inside_null_check() {
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
