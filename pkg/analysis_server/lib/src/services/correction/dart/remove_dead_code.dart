// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/error/dead_code_verifier.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveDeadCode extends ResolvedCorrectionProducer {
  @override
  // Not predictably the correct action.
  bool get canBeAppliedInBulk => false;

  @override
  // Not predictably the correct action.
  bool get canBeAppliedToFile => false;

  @override
  AstNode? get coveredNode {
    var node = super.coveredNode;
    if (node is BinaryExpression) {
      var problemMessage = diagnostic?.problemMessage;
      if (problemMessage != null) {
        var operatorOffset = node.operator.offset;
        var rightOperand = node.rightOperand;
        if (problemMessage.offset == operatorOffset &&
            problemMessage.length == rightOperand.end - operatorOffset) {
          return rightOperand;
        }
      }
    }
    return node;
  }

  @override
  FixKind get fixKind => DartFixKind.REMOVE_DEAD_CODE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final coveredNode = this.coveredNode;
    var parent = coveredNode?.parent;

    if (coveredNode is Expression) {
      if (parent is BinaryExpression) {
        if (parent.rightOperand == coveredNode) {
          await builder.addDartFileEdit(file, (builder) {
            builder.addDeletion(range.endEnd(parent.leftOperand, coveredNode));
          });
        }
      } else if (parent is ForParts) {
        var forStatement = parent.parent;
        if (forStatement is! ForStatement) return;
        await _computeForStatementParts(builder, forStatement, parent);
      }
    } else if (coveredNode is Block) {
      var block = coveredNode;
      var statementsToRemove = <Statement>[];
      var problemMessage = diagnostic?.problemMessage;
      if (problemMessage == null) {
        return;
      }
      var errorRange =
          SourceRange(problemMessage.offset, problemMessage.length);
      for (var statement in block.statements) {
        if (range.node(statement).intersects(errorRange)) {
          statementsToRemove.add(statement);
        }
      }
      if (statementsToRemove.isNotEmpty) {
        var rangeToRemove = utils.getLinesRangeStatements(statementsToRemove);
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(rangeToRemove);
        });
      }
    } else if (coveredNode is Statement) {
      if (coveredNode is EmptyStatement) {
        return;
      }
      if (coveredNode is DoStatement &&
          await _computeDoStatement(builder, coveredNode)) {
        return;
      }

      var rangeToRemove = utils.getLinesRangeStatements([coveredNode]);
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(rangeToRemove);
      });
    } else if (coveredNode is CatchClause && parent is TryStatement) {
      var catchClauses = parent.catchClauses;
      var index = catchClauses.indexOf(coveredNode);
      var previous = index == 0 ? parent.body : catchClauses[index - 1];
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.endEnd(previous, coveredNode));
      });
    } else if (coveredNode is ForParts) {
      var forStatement = coveredNode.parent;
      if (forStatement is! ForStatement) return;

      await _computeForStatementParts(builder, forStatement, coveredNode);
    } else if (coveredNode is SwitchPatternCase) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.deletionRange(coveredNode));
      });
    }
  }

  /// Return `true` if the fix is processed.
  Future<bool> _computeDoStatement(
      ChangeBuilder builder, DoStatement statement) async {
    if (statement.hasBreakStatement) {
      // TODO(asashour): consider modifying the do statement to a label
      // https://github.com/dart-lang/sdk/issues/49091#issuecomment-1135489675
      return true;
    }

    var problemMessage = diagnostic?.problemMessage;
    if (problemMessage != null) {
      var problemOffset = problemMessage.offset;
      var problemLength = problemMessage.length;
      var doKeyword = statement.doKeyword;
      var whileKeyword = statement.whileKeyword;

      Future<void> deleteNoBrackets() async {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.startStart(doKeyword, doKeyword.next!));
          _deleteLineRange(
              builder, range.startEnd(whileKeyword, statement.semicolon));
        });
      }

      Future<void> deleteBrackets(Block block) async {
        await builder.addDartFileEdit(file, (builder) {
          _deleteLineRange(
              builder, range.startEnd(doKeyword, block.leftBracket));
          _deleteLineRange(
              builder, range.startEnd(block.rightBracket, statement.semicolon));
        });
      }

      if (problemOffset == doKeyword.offset) {
        if (problemLength == doKeyword.length) {
          await deleteNoBrackets();
          return true;
        } else {
          var body = statement.body;
          if (body is Block &&
              problemLength == body.leftBracket.end - problemOffset) {
            await deleteBrackets(body);
            return true;
          }
        }
      } else if (problemOffset + problemLength == statement.semicolon.end) {
        if (problemOffset == whileKeyword.offset) {
          await deleteNoBrackets();
          return true;
        } else {
          var body = statement.body;
          if (body is Block && problemOffset == body.rightBracket.offset) {
            await deleteBrackets(body);
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _computeForStatementParts(ChangeBuilder builder,
      ForStatement forStatement, ForParts forParts) async {
    var beginNode = coveredNode;
    if (beginNode == null) return;
    var updaters = forParts.updaters;
    if (!updaters.contains(beginNode)) {
      var problemMessage = diagnostic?.problemMessage;
      if (problemMessage == null) return;

      beginNode = null;
      var problemOffset = problemMessage.offset;
      var problemLength = problemMessage.length;
      var updatersEnd = updaters.endToken!.end;

      for (var node in updaters) {
        var nodeOffset = node.offset;
        if (problemOffset == nodeOffset &&
            problemLength == updatersEnd - nodeOffset) {
          beginNode = node;
          break;
        }
      }
      if (beginNode == null) return;
    }
    var isFirstNode = updaters.first == beginNode;
    var rightParenthesis = forStatement.rightParenthesis;
    var isComma =
        !isFirstNode && rightParenthesis.previous?.type == TokenType.COMMA;

    var previous = beginNode.beginToken.previous!;

    var deletionRange = isComma
        ? range.endStart(previous, rightParenthesis)
        : range.startStart(
            isFirstNode ? beginNode : previous, rightParenthesis);

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(deletionRange);
    });
  }

  void _deleteLineRange(DartFileEditBuilder builder, SourceRange sourceRange) {
    builder.addDeletion(utils.getLinesRange(sourceRange));
  }
}
