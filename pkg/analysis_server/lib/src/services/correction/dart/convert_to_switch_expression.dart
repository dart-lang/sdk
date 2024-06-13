// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToSwitchExpression extends ResolvedCorrectionProducer {
  /// Local variable reference used in assignment switch expression generation.
  LocalVariableElement? writeElement;

  /// Assignment operator used in assignment switch expression generation.
  TokenType? assignmentOperator;

  /// Function reference used in argument switch expression generation.
  FunctionElement? functionElement;

  ConvertToSwitchExpression({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_SWITCH_EXPRESSION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var switchStatement = node;
    if (switchStatement is! SwitchStatementImpl) {
      return;
    }

    ThrowStatement? followingThrow;
    var expression = switchStatement.expression;
    if (!_isEffectivelyExhaustive(switchStatement, expression.typeOrThrow)) {
      followingThrow = switchStatement.followingThrow;
      if (followingThrow == null) {
        return;
      }
    }

    var switchType = _getSupportedSwitchType(switchStatement);
    switch (switchType) {
      case _SwitchTypeReturn():
        await _convertReturnSwitchExpression(
            builder, switchStatement, switchType, followingThrow);
      case _SwitchTypeAssignment():
        await _convertAssignmentSwitchExpression(
            builder, switchStatement, switchType);
      case _SwitchTypeArgument():
        await _convertArgumentSwitchExpression(
            builder, switchStatement, switchType);
      case null:
        return;
    }
  }

  Future<void> _convertArgumentSwitchExpression(
    ChangeBuilder builder,
    SwitchStatement node,
    _SwitchTypeArgument switchType,
  ) async {
    void convertArgumentStatements(
      DartFileEditBuilder builder,
      List<Statement> statements,
      Token lastColon, {
      required bool withTrailingComma,
    }) {
      for (var statement in statements) {
        var hasComment = statement.beginToken.precedingComments != null;

        if (statement is ExpressionStatement) {
          var invocation = statement.expression;
          if (invocation is MethodInvocation) {
            var deletion = !hasComment
                ? range.startOffsetEndOffset(
                    lastColon.end, invocation.argumentList.leftParenthesis.end)
                : range.startOffsetEndOffset(invocation.offset,
                    invocation.argumentList.leftParenthesis.end);
            builder.addDeletion(deletion);
            builder.addDeletion(
                range.entity(invocation.argumentList.rightParenthesis));
          }
        }

        if (!hasComment && statement.isThrowExpressionStatement) {
          var deletionRange =
              range.startOffsetEndOffset(lastColon.end, statement.offset - 1);
          builder.addDeletion(deletionRange);
        }

        if (statement is BreakStatement) {
          var deletion = _getBreakRange(statement);
          builder.addDeletion(deletion);
        } else {
          builder.addSimpleReplacement(
            range.entity(statement.endToken),
            withTrailingComma ? ',' : '',
          );
        }
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(node.offset, '${functionElement!.name}(');

      var groupCount = switchType.groups.length;
      for (var i = 0; i < groupCount; ++i) {
        var group = switchType.groups[i];
        switch (group) {
          case _DefaultGroup():
            _convertSwitchDefault(builder, group.node);
            convertArgumentStatements(
              builder,
              group.statements,
              group.node.colon,
              withTrailingComma: false,
            );
          case _JoinedCaseGroup():
            var firstCase = group.patternCases.first;
            var lastCase = group.patternCases.last;
            var lastColon = lastCase.colon;

            var patternCode = group.patternCases
                .map((patternCase) => patternCase.guardedPattern.pattern)
                .map((pattern) => utils.getNodeText(pattern))
                .join(' || ');
            builder.addSimpleReplacement(
              range.startEnd(firstCase.keyword, lastColon),
              '$patternCode => ',
            );

            convertArgumentStatements(
              builder,
              group.statements,
              lastColon,
              withTrailingComma: i < groupCount - 1,
            );
        }
      }

      builder.addSimpleInsertion(node.end, ');');
    });
  }

  Future<void> _convertAssignmentSwitchExpression(
    ChangeBuilder builder,
    SwitchStatement node,
    _SwitchTypeAssignment switchType,
  ) async {
    void convertAssignmentStatements(
      DartFileEditBuilder builder,
      NodeList<Statement> statements,
      Token lastColon, {
      required bool withTrailingComma,
    }) {
      for (var statement in statements) {
        if (statement is ExpressionStatement) {
          var expression = statement.expression;
          if (expression is AssignmentExpression) {
            var hasComment = statement.beginToken.precedingComments != null;
            var deletion = !hasComment
                ? range.startOffsetEndOffset(
                    lastColon.end, expression.operator.end)
                : range.startOffsetEndOffset(expression.beginToken.offset,
                    expression.rightHandSide.offset);
            builder.addDeletion(deletion);
          } else if (expression is ThrowExpression) {
            var deletionRange =
                range.startOffsetEndOffset(lastColon.end, statement.offset - 1);
            builder.addDeletion(deletionRange);
          }
        }

        if (statement is BreakStatement) {
          var deletion = _getBreakRange(statement);
          builder.addDeletion(deletion);
        } else {
          builder.addSimpleReplacement(
            range.entity(statement.endToken),
            withTrailingComma ? ',' : '',
          );
        }
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(
          node.offset, '${writeElement!.name} ${assignmentOperator!.lexeme} ');

      var groupCount = switchType.groups.length;
      for (var i = 0; i < groupCount; ++i) {
        // TODO(pq): extract shared replacement logic
        var group = switchType.groups[i];
        switch (group) {
          case _DefaultGroup():
            _convertSwitchDefault(builder, group.node);
            convertAssignmentStatements(
              builder,
              group.node.statements,
              group.node.colon,
              withTrailingComma: false,
            );
          case _JoinedCaseGroup():
            var firstCase = group.patternCases.first;
            var lastCase = group.patternCases.last;
            var lastColon = lastCase.colon;

            var patternCode = group.patternCases
                .map((patternCase) => patternCase.guardedPattern.pattern)
                .map((pattern) => utils.getNodeText(pattern))
                .join(' || ');
            builder.addSimpleReplacement(
              range.startEnd(firstCase.keyword, lastColon),
              '$patternCode =>',
            );

            convertAssignmentStatements(
              builder,
              lastCase.statements,
              lastColon,
              withTrailingComma: i < groupCount - 1,
            );
        }
      }

      builder.addSimpleInsertion(node.end, ';');
    });
  }

  Future<void> _convertReturnSwitchExpression(
    ChangeBuilder builder,
    SwitchStatement node2,
    _SwitchTypeReturn switchType,
    ThrowStatement? followingThrow,
  ) async {
    void convertReturnStatement(
      DartFileEditBuilder builder,
      Statement statement,
      Token lastColon, {
      required bool withTrailingComma,
    }) {
      var hasComment = statement.beginToken.precedingComments != null;

      switch (statement) {
        case ReturnStatement():
          // Return expression is sure to be non-null
          var expression = statement.expression!;
          if (!hasComment) {
            builder.addSimpleReplacement(
              range.endStart(lastColon, expression),
              ' ',
            );
          } else {
            builder.addDeletion(
              range.startStart(statement.returnKeyword, expression),
            );
          }
        case ExpressionStatement(expression: ThrowExpression throw_):
          if (!hasComment) {
            builder.addSimpleReplacement(
              range.endStart(lastColon, throw_),
              ' ',
            );
          }
      }

      builder.addSimpleReplacement(
        range.entity(statement.endToken),
        withTrailingComma ? ',' : '',
      );
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(node.offset, 'return ');
      builder.addSimpleInsertion(node.end, ';');

      var groupCount = switchType.groups.length;
      for (var i = 0; i < groupCount; ++i) {
        // TODO(pq): extract shared replacement logic
        var group = switchType.groups[i];
        switch (group) {
          case _DefaultGroup():
            _convertSwitchDefault(builder, group.node);
            convertReturnStatement(
              builder,
              group.statements.first,
              group.node.colon,
              withTrailingComma: false,
            );
          case _JoinedCaseGroup():
            var firstCase = group.patternCases.first;
            var lastCase = group.patternCases.last;

            var patternCode = group.patternCases
                .map((patternCase) => patternCase.guardedPattern.pattern)
                .map((pattern) => utils.getNodeText(pattern))
                .join(' || ');
            builder.addSimpleReplacement(
              range.startEnd(
                firstCase.keyword,
                lastCase.colon,
              ),
              '$patternCode =>',
            );

            var statement = group.statements.first;
            convertReturnStatement(
              builder,
              statement,
              lastCase.colon,
              withTrailingComma: i < groupCount - 1 || followingThrow != null,
            );
        }
      }

      if (followingThrow != null) {
        var throwText = utils.getNodeText(followingThrow.expression);
        _insertLinesBefore(
          builder: builder,
          nextLineOffset: node2.rightBracket.offset,
          text: '_ => $throwText,',
          indentation: _IndentationFullFirstRightAll(level: 1),
        );
        _deleteStatements(builder, [followingThrow.statement]);
      }
    });
  }

  void _convertSwitchDefault(
      DartFileEditBuilder builder, SwitchDefault member) {
    var defaultClauseRange = range.startEnd(member.keyword, member.colon);
    builder.addSimpleReplacement(defaultClauseRange, '_ =>');
  }

  void _deleteStatements(
    DartFileEditBuilder builder,
    List<Statement> statements,
  ) {
    var range = utils.getLinesRangeStatements(statements);
    builder.addDeletion(range);
  }

  _SwitchType? _getSupportedSwitchType(SwitchStatementImpl node) {
    var memberGroups = node.memberGroups;
    if (memberGroups.isEmpty) {
      return null;
    }

    var hasValidGroups = true;
    var canBeReturn = true;
    var canBeAssignment = true;
    var canBeArgument = true;
    var result = <_Group>[];

    for (var group in memberGroups) {
      var members = group.members;

      if (members.any((e) => e.labels.isNotEmpty)) {
        return null;
      }

      // Build groups.
      () {
        // Support `default`, if alone.
        if (members.singleOrNull case SwitchDefault switchDefault) {
          result.add(
            _DefaultGroup(
              node: switchDefault,
              statements: group.statements,
            ),
          );
          return;
        }

        var patternCases = members.whereType<SwitchPatternCase>().toList();
        if (patternCases.length != members.length) {
          hasValidGroups = false;
          return;
        }

        // For single `GuardedPattern` we allow `when`.
        // For joined `GuardedPattern`s, we cannot support any `when`.
        if (patternCases.length != 1) {
          if (patternCases.hasWhen) {
            hasValidGroups = false;
            return;
          }
        }

        result.add(
          _JoinedCaseGroup(
            patternCases: patternCases,
            statements: group.statements,
          ),
        );
      }();
      if (!hasValidGroups) {
        return null;
      }

      var statements = group.statements;
      // We currently only support converting switch members
      // with one non-break statement.
      if (statements.isEmpty || statements.length > 2) {
        return null;
      }

      if (statements case [_, var secondStatement]) {
        // If there is a second statement, it must be a break statement.
        if (secondStatement is! BreakStatement) return null;

        // A return switch case can't have a second statement.
        canBeReturn = false;
      }

      var statement = statements.first;
      if (statement is ExpressionStatementImpl) {
        var expression = statement.expression;
        // Any type of switch can have a throw expression as a statement.
        if (expression is ThrowExpression) {
          if (memberGroups.length == 1) {
            // If there is only one case and it's a throw expression,
            // then assume it's a return switch.
            canBeAssignment = false;
            canBeArgument = false;
          }
          continue;
        }

        // A return switch case's statement can't be a non-throw expression.
        canBeReturn = false;

        if (canBeArgument && expression is MethodInvocationImpl) {
          // An assignment switch case's statement can't be a method invocation.
          canBeAssignment = false;

          var element = expression.methodName.staticElement;
          if (element is! FunctionElement) return null;
          if (functionElement == null) {
            functionElement = element;
          } else if (functionElement != element) {
            // The function invoked in each case must be the same.
            return null;
          }
        } else if (canBeAssignment && expression is AssignmentExpressionImpl) {
          // An argument switch case's statement can't be an assignment.
          canBeArgument = false;

          var leftHandSide = expression.leftHandSide;
          if (leftHandSide is! SimpleIdentifierImpl) return null;
          if (writeElement == null) {
            var element = leftHandSide.staticElement;
            if (element is! LocalVariableElement) return null;
            writeElement = element;
            assignmentOperator = expression.operator.type;
          } else if (writeElement != leftHandSide.staticElement ||
              expression.operator.type != assignmentOperator) {
            // The variable written to and the assignment operator used
            // in each case must be the same.
            return null;
          }
        } else {
          // The expression has an unsupported type.
          return null;
        }
      } else {
        // If the statement is not an expression,
        // it must be a return statement with a
        // non-null expression as part of a return switch.
        if (!canBeReturn ||
            statement is! ReturnStatementImpl ||
            statement.expression == null) {
          return null;
        }

        canBeAssignment = false;
        canBeArgument = false;
      }

      if (!canBeReturn && !canBeAssignment && !canBeArgument) {
        return null;
      }
    }

    if (canBeReturn) {
      assert(!canBeAssignment && !canBeArgument);
      return _SwitchTypeReturn(
        groups: result,
      );
    } else if (canBeAssignment) {
      assert(!canBeArgument);
      return _SwitchTypeAssignment(
        groups: result,
      );
    } else if (canBeArgument) {
      return _SwitchTypeArgument(
        groups: result,
      );
    }

    return null;
  }

  /// Adds [level] indents to each line.
  String _indentRight(String text, {int level = 1}) {
    var buffer = StringBuffer();
    var indent = utils.oneIndent * level;
    var eol = utils.endOfLine;
    var lines = text.split(eol);
    for (var line in lines) {
      if (buffer.isNotEmpty) {
        buffer.write(eol);
      }
      buffer.write('$indent$line');
    }
    return buffer.toString();
  }

  /// Given [nextLineOffset] that is an offset on the next line (the line
  /// before which we want to insert), inserts potentially multi-line [text]
  /// as separate full lines. Always adds EOL after [text].
  void _insertLinesBefore({
    required DartFileEditBuilder builder,
    required int nextLineOffset,
    required String text,
    required _Indentation indentation,
  }) {
    var insertOffset = utils.getLineContentStart(nextLineOffset);
    var nextLinePrefix = utils.getLinePrefix(nextLineOffset);

    switch (indentation) {
      case _IndentationFullFirstRightAll():
        var indentedText = _indentRight(
          nextLinePrefix + text,
          level: indentation.level,
        );
        var withEol = '$indentedText$eol';
        builder.addSimpleInsertion(insertOffset, withEol);
    }
  }

  bool _isEffectivelyExhaustive(
    SwitchStatement node,
    DartType? expressionType,
  ) {
    if (expressionType == null) return false;
    if ((typeSystem as TypeSystemImpl).isAlwaysExhaustive(expressionType)) {
      return true;
    }
    var last = node.members.lastOrNull;
    if (last is SwitchPatternCase) {
      var pattern = last.guardedPattern.pattern;
      return pattern is WildcardPattern;
    }
    return last is SwitchDefault;
  }

  static SourceRange _getBreakRange(BreakStatement statement) {
    var previous = (statement.beginToken.precedingComments ??
        statement.beginToken.previous)!;
    var deletion =
        range.startOffsetEndOffset(previous.end, statement.endToken.end);
    return deletion;
  }
}

class _DefaultGroup extends _Group {
  final SwitchDefault node;

  _DefaultGroup({
    required super.statements,
    required this.node,
  });
}

sealed class _Group {
  final List<Statement> statements;

  _Group({
    required this.statements,
  });
}

/// Superclass for all indentation strategies.
sealed class _Indentation {}

/// The first line should be indented with the full line indentation of the
/// following (target) line, and all lines (including the first) should be
/// indented [level] positions to the right.
final class _IndentationFullFirstRightAll extends _Indentation {
  final int level;

  _IndentationFullFirstRightAll({
    required this.level,
  });
}

/// Joined [Pattern]s, without `when`, before statements.
class _JoinedCaseGroup extends _Group {
  final List<SwitchPatternCase> patternCases;

  _JoinedCaseGroup({
    required this.patternCases,
    required super.statements,
  });
}

sealed class _SwitchType {
  final List<_Group> groups;

  _SwitchType({
    required this.groups,
  });
}

/// Each case statement passes a value to the same function.
final class _SwitchTypeArgument extends _SwitchType {
  _SwitchTypeArgument({
    required super.groups,
  });
}

/// Each case statement assigns to a local variable.
final class _SwitchTypeAssignment extends _SwitchType {
  _SwitchTypeAssignment({
    required super.groups,
  });
}

/// Each case statement returns a value.
final class _SwitchTypeReturn extends _SwitchType {
  _SwitchTypeReturn({
    required super.groups,
  });
}

extension on Statement {
  bool get isThrowExpressionStatement {
    var self = this;
    if (self is! ExpressionStatement) return false;
    return self.expression is ThrowExpression;
  }
}

extension on List<SwitchPatternCase> {
  bool get hasWhen {
    return any((e) => e.guardedPattern.whenClause != null);
  }
}
