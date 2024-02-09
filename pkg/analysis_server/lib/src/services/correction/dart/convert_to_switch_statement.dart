// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertIfStatementToSwitchStatement extends ResolvedCorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_SWITCH_STATEMENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!libraryElement.featureSet.isEnabled(Feature.patterns)) {
      return;
    }

    final ifStatement = node;
    if (ifStatement is! IfStatement) {
      return;
    }

    final cases = _buildCases(ifStatement);
    if (cases == null) {
      return;
    }

    final firstThen = cases.firstOrNull;
    if (firstThen is! _IfCaseThen) {
      return;
    }

    final indent = utils.getLinePrefix(ifStatement.offset);
    final singleIndent = utils.getIndent(1);
    final caseIndent = '$indent$singleIndent';

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(ifStatement), (builder) {
        final expressionCode = firstThen.expressionCode;
        builder.writeln('switch ($expressionCode) {');

        for (final case_ in cases) {
          switch (case_) {
            case _IfCaseThen():
              final patternCode = case_.patternCode;
              builder.writeln('${caseIndent}case $patternCode:');
              _writeStatement(
                builder: builder,
                statement: case_.statement,
                ifStatementIndent: indent,
              );
            case _IfCaseElse():
              builder.writeln('${caseIndent}default:');
              _writeStatement(
                builder: builder,
                statement: case_.statement,
                ifStatementIndent: indent,
              );
          }
        }

        builder.write('$indent}');
      });
    });
  }

  List<_IfCase>? _buildCases(IfStatement ifStatement) {
    final thenCase = _buildThenCase(ifStatement);
    if (thenCase == null) {
      return null;
    }

    final cases = <_IfCase>[];
    cases.add(thenCase);

    final elseStatement = ifStatement.elseStatement;
    if (elseStatement is IfStatement) {
      final elseCases = _buildCases(elseStatement);
      if (elseCases == null) {
        return null;
      }
      for (final elseCase in elseCases) {
        if (elseCase is _IfCaseThen) {
          if (elseCase.expressionCode != thenCase.expressionCode) {
            return null;
          }
        }
        cases.add(elseCase);
      }
    } else if (elseStatement != null) {
      cases.add(
        _IfCaseElse(
          statement: elseStatement,
        ),
      );
    }

    return cases;
  }

  _IfCaseThen? _buildThenCase(IfStatement ifStatement) {
    final expression = ifStatement.expression;
    final caseClause = ifStatement.caseClause;

    if (caseClause != null) {
      if (expression is! SimpleIdentifier) {
        return null;
      }
      final guardedPattern = caseClause.guardedPattern;
      final patternCode = utils.getNodeText(guardedPattern);
      return _IfCaseThen(
        expressionCode: expression.token.lexeme,
        patternCode: patternCode,
        statement: ifStatement.thenStatement,
      );
    }

    // The expression is the bool condition.
    final result = utils.patternOfBoolCondition(expression);
    if (result == null) {
      return null;
    }

    return _IfCaseThen(
      expressionCode: result.expressionCode,
      patternCode: result.patternCode,
      statement: ifStatement.thenStatement,
    );
  }

  /// Writes [statement], if it is a [Block], inlines it.
  void _writeStatement({
    required DartEditBuilder builder,
    required Statement statement,
    required String ifStatementIndent,
  }) {
    final statements = statement.selfOrBlockStatements;
    final range = utils.getLinesRangeStatements(statements);

    // if
    //   statement
    // switch
    //   case
    //     statement
    final singleIndent = utils.getIndent(1);
    final newIndent = '$ifStatementIndent$singleIndent';

    final code = utils.replaceSourceRangeIndent(
      range,
      ifStatementIndent,
      newIndent,
      includeLeading: true,
      ensureTrailingNewline: true,
    );

    builder.write(code);
  }
}

class ConvertSwitchExpressionToSwitchStatement
    extends ResolvedCorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_SWITCH_STATEMENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final switchExpression = node;
    if (switchExpression is! SwitchExpression) {
      return;
    }

    await _singleVariableDeclaration(
      builder: builder,
      switchExpression: switchExpression,
    );

    await _variableAssignment(
      builder: builder,
      switchExpression: switchExpression,
    );

    await _returnStatement(
      builder: builder,
      switchExpression: switchExpression,
    );
  }

  Future<void> _returnStatement({
    required ChangeBuilder builder,
    required SwitchExpression switchExpression,
  }) async {
    final returnStatement = switchExpression.parent;
    if (returnStatement is! ReturnStatement) {
      return;
    }

    final indent = utils.getLinePrefix(returnStatement.offset);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.startStart(returnStatement.returnKeyword, switchExpression),
        '',
      );
      _rewriteCases(
        switchExpression: switchExpression,
        builder: builder,
        indent: indent,
        beforeCaseExpression: 'return ',
        semicolon: returnStatement.semicolon,
      );
    });
  }

  Future<void> _rewriteCases({
    required SwitchExpression switchExpression,
    required DartFileEditBuilder builder,
    required String indent,
    required String beforeCaseExpression,
    required Token semicolon,
  }) async {
    for (final case_ in switchExpression.cases) {
      final guardedPattern = case_.guardedPattern;
      // `_ =>` -> `default:`
      // `X _ =>` -> `X _:`
      if (guardedPattern.isPureUntypedWildcard) {
        builder.addSimpleReplacement(
          range.node(guardedPattern),
          'default',
        );
      } else {
        builder.addSimpleInsertion(guardedPattern.offset, 'case ');
      }
      // `=> ex,` -> `return X;`
      builder.addSimpleReplacement(
        range.endStart(guardedPattern, case_.expression),
        ':$eol$indent    $beforeCaseExpression',
      );
      // Replace `,` with `;` or just insert `;`.
      final comma = case_.expression.endToken.next;
      if (comma != null && comma.type == TokenType.COMMA) {
        builder.addSimpleReplacement(range.token(comma), ';');
      } else {
        builder.addSimpleInsertion(case_.expression.end, ';');
      }
    }
    builder.addDeletion(
      range.token(semicolon),
    );
  }

  Future<void> _singleVariableDeclaration({
    required ChangeBuilder builder,
    required SwitchExpression switchExpression,
  }) async {
    final declaration = switchExpression.parent;
    if (declaration is! VariableDeclaration) {
      return;
    }

    final declarationList = declaration.parent;
    if (declarationList is! VariableDeclarationList) {
      return;
    }
    if (declarationList.variables.length != 1) {
      return;
    }

    final declarationStatement = declarationList.parent;
    if (declarationStatement is! VariableDeclarationStatement) {
      return;
    }

    final indent = utils.getLinePrefix(declarationStatement.offset);

    await builder.addDartFileEdit(file, (builder) {
      // Replace implicit type with explicit.
      if (declarationList.type == null) {
        final keyword = declarationList.keyword;
        if (keyword != null) {
          if (keyword.keyword == Keyword.FINAL) {
            builder.addReplacement(
              range.startLength(declaration.name, 0),
              (builder) {
                builder.writeType(switchExpression.typeOrThrow);
                builder.write(' ');
              },
            );
          } else {
            builder.addReplacement(
              range.token(keyword),
              (builder) {
                builder.writeType(switchExpression.typeOrThrow);
              },
            );
          }
        }
      }
      // Split variable declaration.
      builder.addSimpleReplacement(
        range.endStart(declaration.name, switchExpression),
        ';$eol$indent',
      );
      _rewriteCases(
        switchExpression: switchExpression,
        builder: builder,
        indent: indent,
        beforeCaseExpression: '${declaration.name.lexeme} = ',
        semicolon: declarationStatement.semicolon,
      );
    });
  }

  Future<void> _variableAssignment({
    required ChangeBuilder builder,
    required SwitchExpression switchExpression,
  }) async {
    final assignment = switchExpression.parent;
    if (assignment is! AssignmentExpression) {
      return;
    }
    if (assignment.rightHandSide != switchExpression) {
      return;
    }

    final variableId = assignment.leftHandSide;
    if (variableId is! SimpleIdentifier) {
      return;
    }

    final expressionStatement = assignment.parent;
    if (expressionStatement is! ExpressionStatement) {
      return;
    }

    final semicolon = expressionStatement.semicolon;
    if (semicolon == null) {
      return;
    }

    final indent = utils.getLinePrefix(expressionStatement.offset);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.startStart(variableId, switchExpression),
        '',
      );
      _rewriteCases(
        switchExpression: switchExpression,
        builder: builder,
        indent: indent,
        beforeCaseExpression: '${variableId.token.lexeme} = ',
        semicolon: semicolon,
      );
    });
  }
}

sealed class _IfCase {
  final Statement statement;

  _IfCase({
    required this.statement,
  });
}

class _IfCaseElse extends _IfCase {
  _IfCaseElse({
    required super.statement,
  });
}

class _IfCaseThen extends _IfCase {
  final String expressionCode;
  final String patternCode;

  _IfCaseThen({
    required this.expressionCode,
    required this.patternCode,
    required super.statement,
  });
}

extension on GuardedPattern {
  bool get isPureUntypedWildcard {
    if (whenClause == null) {
      final pattern = this.pattern;
      return pattern is WildcardPattern && pattern.type == null;
    }
    return false;
  }
}
