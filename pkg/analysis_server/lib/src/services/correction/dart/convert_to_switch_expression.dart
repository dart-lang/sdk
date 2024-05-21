// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
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

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_SWITCH_EXPRESSION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var switchStatement = node;
    if (switchStatement is! SwitchStatement) return;

    ThrowStatement? followingThrow;
    var expression = switchStatement.expression;
    if (!isEffectivelyExhaustive(switchStatement, expression.typeOrThrow)) {
      followingThrow = switchStatement.followingThrow;
      if (followingThrow == null) {
        return;
      }
    }

    switch (_getSupportedSwitchType(switchStatement)) {
      case _SupportedSwitchType.returnValue:
        await convertReturnSwitchExpression(
            builder, switchStatement, followingThrow);
      case _SupportedSwitchType.assignment:
        await convertAssignmentSwitchExpression(builder, switchStatement);
      case _SupportedSwitchType.argument:
        await convertArgumentSwitchExpression(builder, switchStatement);
      case null:
        return;
    }
  }

  Future<void> convertArgumentSwitchExpression(
      ChangeBuilder builder, SwitchStatement node) async {
    void convertArgumentStatements(DartFileEditBuilder builder,
        NodeList<Statement> statements, SourceRange colonRange,
        {String endToken = ''}) {
      for (var statement in statements) {
        var hasComment = statement.beginToken.precedingComments != null;

        if (statement is ExpressionStatement) {
          var invocation = statement.expression;
          if (invocation is MethodInvocation) {
            var deletion = !hasComment
                ? range.startOffsetEndOffset(
                    range.offsetBy(colonRange, 1).offset,
                    invocation.argumentList.leftParenthesis.end)
                : range.startOffsetEndOffset(invocation.offset,
                    invocation.argumentList.leftParenthesis.end);
            builder.addDeletion(deletion);
            builder.addDeletion(
                range.entity(invocation.argumentList.rightParenthesis));
          }
        }

        if (!hasComment && statement.isThrowExpressionStatement) {
          var deletionRange = range.startOffsetEndOffset(
              range.offsetBy(colonRange, 1).offset, statement.offset - 1);
          builder.addDeletion(deletionRange);
        }

        if (statement is BreakStatement) {
          var deletion = getBreakRange(statement);
          builder.addDeletion(deletion);
        } else {
          builder.addSimpleReplacement(
              range.entity(statement.endToken), endToken);
        }
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(node.offset, '${functionElement!.name}(');

      var memberCount = node.members.length;
      for (var i = 0; i < memberCount; ++i) {
        var member = node.members[i];
        if (member is SwitchDefault) {
          convertSwitchDefault(builder, member);
          convertArgumentStatements(
              builder, member.statements, range.entity(member.colon));
          continue;
        }
        // Sure to be a SwitchPatternCase
        var patternCase = member as SwitchPatternCase;
        builder.addDeletion(
            range.startStart(patternCase.keyword, patternCase.guardedPattern));
        var colonRange = range.entity(patternCase.colon);
        builder.addSimpleReplacement(colonRange, ' => ');

        var endToken = i < memberCount - 1 ? ',' : '';
        convertArgumentStatements(builder, patternCase.statements, colonRange,
            endToken: endToken);
      }

      builder.addSimpleInsertion(node.end, ');');
    });
  }

  Future<void> convertAssignmentSwitchExpression(
      ChangeBuilder builder, SwitchStatement node) async {
    void convertAssignmentStatements(DartFileEditBuilder builder,
        NodeList<Statement> statements, SourceRange colonRange,
        {String endToken = ''}) {
      for (var statement in statements) {
        if (statement is ExpressionStatement) {
          var expression = statement.expression;
          if (expression is AssignmentExpression) {
            var hasComment = statement.beginToken.precedingComments != null;
            var deletion = !hasComment
                ? range.startOffsetEndOffset(
                    range.offsetBy(colonRange, 1).offset,
                    expression.operator.end)
                : range.startOffsetEndOffset(expression.beginToken.offset,
                    expression.rightHandSide.offset);
            builder.addDeletion(deletion);
          } else if (expression is ThrowExpression) {
            var deletionRange = range.startOffsetEndOffset(
                range.offsetBy(colonRange, 1).offset, statement.offset - 1);
            builder.addDeletion(deletionRange);
          }
        }

        if (statement is BreakStatement) {
          var deletion = getBreakRange(statement);
          builder.addDeletion(deletion);
        } else {
          builder.addSimpleReplacement(
              range.entity(statement.endToken), endToken);
        }
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(
          node.offset, '${writeElement!.name} ${assignmentOperator!.lexeme} ');

      var memberCount = node.members.length;
      for (var i = 0; i < memberCount; ++i) {
        // TODO(pq): extract shared replacement logic
        var member = node.members[i];
        if (member is SwitchDefault) {
          convertSwitchDefault(builder, member);
          convertAssignmentStatements(
              builder, member.statements, range.entity(member.colon));
          continue;
        }

        // Sure to be a SwitchPatternCase
        var patternCase = member as SwitchPatternCase;
        builder.addDeletion(
            range.startStart(patternCase.keyword, patternCase.guardedPattern));
        var colonRange = range.entity(patternCase.colon);
        builder.addSimpleReplacement(colonRange, ' =>');

        var endToken = i < memberCount - 1 ? ',' : '';
        convertAssignmentStatements(builder, patternCase.statements, colonRange,
            endToken: endToken);
      }

      builder.addSimpleInsertion(node.end, ';');
    });
  }

  Future<void> convertReturnSwitchExpression(
    ChangeBuilder builder,
    SwitchStatement node,
    ThrowStatement? followingThrow,
  ) async {
    void convertReturnStatement(DartFileEditBuilder builder,
        Statement statement, SourceRange colonRange,
        {String endToken = ''}) {
      var hasComment = statement.beginToken.precedingComments != null;

      if (statement is ReturnStatement) {
        // Return expression is sure to be non-null
        var deletion = !hasComment
            ? range.startOffsetEndOffset(range.offsetBy(colonRange, 1).offset,
                statement.expression!.offset - 1)
            : range.startStart(statement.returnKeyword, statement.expression!);
        builder.addDeletion(deletion);
      }

      if (!hasComment && statement.isThrowExpressionStatement) {
        var deletionRange = range.startOffsetEndOffset(
            range.offsetBy(colonRange, 1).offset, statement.offset - 1);
        builder.addDeletion(deletionRange);
      }

      builder.addSimpleReplacement(range.entity(statement.endToken), endToken);
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(node.offset, 'return ');
      builder.addSimpleInsertion(node.end, ';');

      var memberCount = node.members.length;
      for (var i = 0; i < memberCount; ++i) {
        // TODO(pq): extract shared replacement logic
        var member = node.members[i];
        if (member is SwitchDefault) {
          convertSwitchDefault(builder, member);
          convertReturnStatement(
              builder, member.statements.first, range.entity(member.colon));
          continue;
        }
        // Sure to be a SwitchPatternCase
        var patternCase = member as SwitchPatternCase;
        builder.addDeletion(
            range.startStart(patternCase.keyword, patternCase.guardedPattern));
        var colonRange = range.entity(patternCase.colon);
        builder.addSimpleReplacement(colonRange, ' =>');

        var statement = patternCase.statements.first;
        var endToken = i < memberCount - 1 || followingThrow != null ? ',' : '';
        convertReturnStatement(builder, statement, colonRange,
            endToken: endToken);
      }

      if (followingThrow != null) {
        var throwText = utils.getNodeText(followingThrow.expression);
        _insertLinesBefore(
          builder: builder,
          nextLineOffset: node.rightBracket.offset,
          text: '_ => $throwText,',
          indentation: _IndentationFullFirstRightAll(level: 1),
        );
        _deleteStatements(builder, [followingThrow.statement]);
      }
    });
  }

  void convertSwitchDefault(DartFileEditBuilder builder, SwitchDefault member) {
    var defaultClauseRange = range.startEnd(member.keyword, member.colon);
    builder.addSimpleReplacement(defaultClauseRange, '_ =>');
  }

  SourceRange getBreakRange(BreakStatement statement) {
    var previous = (statement.beginToken.precedingComments ??
        statement.beginToken.previous)!;
    var deletion =
        range.startOffsetEndOffset(previous.end, statement.endToken.end);
    return deletion;
  }

  /// Adds [level] indents to each line.
  String indentRight(String text, {int level = 1}) {
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

  bool isEffectivelyExhaustive(SwitchStatement node, DartType? expressionType) {
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

  void _deleteStatements(
    DartFileEditBuilder builder,
    List<Statement> statements,
  ) {
    var range = utils.getLinesRangeStatements(statements);
    builder.addDeletion(range);
  }

  _SupportedSwitchType? _getSupportedSwitchType(SwitchStatement node) {
    var members = node.members;
    if (members.isEmpty) {
      return null;
    }

    var canBeReturn = true;
    var canBeAssignment = true;
    var canBeArgument = true;

    for (var member in members) {
      // Each member must be a pattern-based case or a default.
      if (member is! SwitchPatternCase && member is! SwitchDefault) {
        return null;
      }

      if (member.labels.isNotEmpty) return null;

      var statements = member.statements;
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
      if (statement is ExpressionStatement) {
        var expression = statement.expression;
        // Any type of switch can have a throw expression as a statement.
        if (expression is ThrowExpression) {
          if (members.length == 1) {
            // If there is only one case and it's a throw expression,
            // then assume it's a return switch.
            canBeAssignment = false;
            canBeArgument = false;
          }
          continue;
        }

        // A return switch case's statement can't be a non-throw expression.
        canBeReturn = false;

        if (canBeArgument && expression is MethodInvocation) {
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
        } else if (canBeAssignment && expression is AssignmentExpression) {
          // An argument switch case's statement can't be an assignment.
          canBeArgument = false;

          var leftHandSide = expression.leftHandSide;
          if (leftHandSide is! SimpleIdentifier) return null;
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
            statement is! ReturnStatement ||
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
      return _SupportedSwitchType.returnValue;
    } else if (canBeAssignment) {
      assert(!canBeArgument);
      return _SupportedSwitchType.assignment;
    } else if (canBeArgument) {
      return _SupportedSwitchType.argument;
    }

    return null;
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
        var indentedText = indentRight(
          nextLinePrefix + text,
          level: indentation.level,
        );
        var withEol = '$indentedText$eol';
        builder.addSimpleInsertion(insertOffset, withEol);
    }
  }
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

/// The different switch types supported by this conversion.
enum _SupportedSwitchType {
  /// Each case statement returns a value.
  returnValue,

  /// Each case statement assigns to a local variable.
  assignment,

  /// Each case statement passes a value to the same function.
  argument,
}

extension on Statement {
  bool get isThrowExpressionStatement {
    var self = this;
    if (self is! ExpressionStatement) return false;
    return self.expression is ThrowExpression;
  }
}
