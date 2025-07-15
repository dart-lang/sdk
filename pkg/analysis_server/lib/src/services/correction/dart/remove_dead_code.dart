// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/error/dead_code_verifier.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveDeadCode extends ResolvedCorrectionProducer {
  late final ChangeBuilder _builder;
  late final int _errorOffset;
  late final int _errorEnd;

  RemoveDeadCode({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Not predictably the correct action.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_DEAD_CODE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    _builder = builder;
    // A given range of dead code may cover multiple expressions or statements,
    // in which case `coveringNode` may include code that's not dead. So rather
    // than start with `coveringNode`, find the innermost AST node that covers
    // the start of the dead code range, and then walk up the AST from there.
    var diagnostic = this.diagnostic;
    if (diagnostic == null) {
      assert(false, 'Dead code removal requires a dead_code diagnostic');
      return Future.value();
    }
    _errorOffset = diagnostic.problemMessage.offset;
    var errorLength = diagnostic.problemMessage.length;
    _errorEnd = _errorOffset + errorLength;

    var node = unit.nodeCovering(offset: _errorOffset);
    if (node == null) {
      assert(
        false,
        'Could not find an AST node corresponding to dead_code range',
      );
      return;
    }
    if (node.offset == diagnosticOffset) {
      // The dead code warning starts at the beginning of `node`. Use this node
      // as the starting point for dead code removal, or, if there is a larger
      // AST node that is fully contained in the dead code range, use it as the
      // starting point.
      node = _findBiggestFullyDeadAncestor(node);
      await _handleDeadAtStartOfNode(node);
    } else if (node.end <= _errorEnd) {
      // The dead code warning starts somewhere inside `node` and continues
      // up to (and possibly beyond) the end of `node`.
      await _handleDeadAtEndOfNode(node);
    } else {
      // The dead code warning starts somewhere inside `node` and ends somewhere
      // inside `node`. It's not possible to eliminate dead code in this
      // scenario.
    }
  }

  Future<void> _addEdit(
    FutureOr<void> Function(DartFileEditBuilder) buildFileEdit,
  ) => _builder.addDartFileEdit(file, buildFileEdit);

  void _deleteLineRange(DartFileEditBuilder builder, SourceRange sourceRange) {
    builder.addDeletion(utils.getLinesRange(sourceRange));
  }

  AstNode _findBiggestFullyDeadAncestor(AstNode node) {
    while (true) {
      var parent = node.parent;
      if (parent == null ||
          parent.offset < _errorOffset ||
          parent.end > _errorEnd) {
        return node;
      }
      node = parent;
    }
  }

  /// Generates the appropriate correction (if any) to handle the case where the
  /// dead code warning starts somewhere inside `node` and continues up to (and
  /// possibly beyond) the end of `node`.
  Future<void> _handleDeadAtEndOfNode(AstNode node) async {
    switch (node) {
      case BinaryExpression(:var leftOperand, :var operator)
          when operator.offset == diagnosticOffset &&
              const [
                TokenType.AMPERSAND_AMPERSAND,
                TokenType.BAR_BAR,
                TokenType.QUESTION_QUESTION,
              ].contains(operator.type):
        // Dead code is the RHS of a short-cutting binary operation (e.g.
        // `true || expr`). The fix is to remove the operator and the RHS.
        await _addEdit((builder) {
          builder.addDeletion(range.endEnd(leftOperand, node));
        });
      case Block(:var rightBracket)
          when rightBracket.offset == diagnosticOffset:
        // Dead code starts at the `}` of a block. It's not possible to remove
        // the `}`, but if any dead code follows the block, it may be removed.
        await _removeDeadCodeAfter(partiallyDeadNode: node);
      case DoStatement(:var body, :var whileKeyword)
          when whileKeyword.offset == diagnosticOffset:
        // Dead code starts at the `while` keyword of a `do` loop. This means
        // the body of the loop is partially dead, so the situation is handled
        // by `_removeDeadCodeAfter`.
        await _removeDeadCodeAfter(partiallyDeadNode: body);
    }
  }

  /// Generates the appropriate correction (if any) to handle the case where the
  /// dead code warning starts at the beginning of `node`.
  Future<void> _handleDeadAtStartOfNode(AstNode node) async {
    switch (node) {
      case CatchClause(:TryStatement parent):
        assert(
          _errorEnd >= node.end,
          'The beginning of a catch clause is dead, so the entire catch clause '
          'should be dead',
        );
        var catchClauses = parent.catchClauses;
        var index = catchClauses.indexOf(node);
        var previous = index == 0 ? parent.body : catchClauses[index - 1];
        await _addEdit((builder) {
          builder.addDeletion(range.endEnd(previous, node));
        });
      case Expression(:ForParts parent) when parent.updaters.contains(node):
        assert(
          _errorEnd >= parent.updaters.last.end,
          'One of the updaters in a for loop is dead, so all the updaters that '
          'follow should be dead too',
        );
        var isFirstNode = parent.updaters.first == node;
        var rightParenthesis = parent.parent.rightParenthesis;
        var isComma =
            !isFirstNode && rightParenthesis.previous?.type == TokenType.COMMA;
        var previous = node.beginToken.previous!;
        var deletionRange =
            isComma
                ? range.endStart(previous, rightParenthesis)
                : range.startStart(
                  isFirstNode ? node : previous,
                  rightParenthesis,
                );
        await _addEdit((builder) {
          builder.addDeletion(deletionRange);
        });
      case Expression(
            parent: ConditionalExpression(
                  parent: var grandParent,
                  :var condition,
                  :var thenExpression,
                  :var elseExpression,
                ) &&
                var parent,
          )
          when (node == thenExpression || node == elseExpression) &&
              _looksSideEffectFree(condition):
        // Then expression is `condition ? live : dead` or
        // `condition ? dead : live`, with a condition that is free of side
        // effects (or so we presume--see `_looksSideEffectFree` for details).
        // So the conditional expression can be replaced with the `live`
        // subexpression.
        var nodeToKeep =
            node == thenExpression ? elseExpression : thenExpression;
        if (nodeToKeep is ThrowExpression &&
            grandParent is CascadeExpression &&
            grandParent.target == parent) {
          // It's not safe to transform something like
          // `a ? b : throw c..cascadeSection` into `throw c..cascadeSection`,
          // because the former parses as `(a ? b : throw c)..cascadeSection`,
          // and the latter parses as `throw (c..cascadeSection)`. This is
          // unlikely to arise in practice, so just bail out and don't generate
          // a correction.
          return;
        }
        await _addEdit((builder) {
          builder.addDeletion(range.startStart(parent, nodeToKeep));
          builder.addDeletion(range.endEnd(nodeToKeep, parent));
        });
      case Statement(
            parent: IfStatement(
                  :var expression,
                  caseClause: null,
                  :var thenStatement,
                  :var elseStatement,
                ) &&
                var ifStatement,
          )
          when _looksSideEffectFree(expression):
        if (node == thenStatement) {
          if (elseStatement == null) {
            // The "if" statement is `if (expression) dead;`, so it can be
            // removed in its entirety.
            await _removeStatement(ifStatement);
          } else {
            // The "if" statement is `if (expression) dead; else live;`, so it
            // can be replaced with `live;`.
            await _replaceStatementWithInnerStatement(
              ifStatement,
              elseStatement,
            );
          }
        } else if (node == elseStatement) {
          // The "if" statement is `if (expression) live; else dead;`, so it can
          // be replaced with `live;`.
          await _replaceStatementWithInnerStatement(ifStatement, thenStatement);
        }
      case Statement(:Block parent):
        var lastStatementInBlock = parent.statements.last;
        assert(
          _errorEnd >= lastStatementInBlock.end,
          'One of the statements in a block is dead, so all the statements '
          'that follow should be dead too',
        );
        await _addEdit((builder) {
          builder.addDeletion(
            utils.getLinesRange(range.startEnd(node, lastStatementInBlock)),
          );
        });
      case SwitchMember(:SwitchStatement parent, :var colon):
        var memberIndex = parent.members.indexOf(node);
        Token? overrideEnd;
        if (memberIndex > 0 &&
            parent.members[memberIndex - 1].statements.isEmpty) {
          // Previous member "falls through" to the one being removed, so don't
          // remove the statements.
          overrideEnd = colon;
        }
        await _addEdit((builder) {
          builder.addDeletion(
            range.deletionRange(node, overrideEnd: overrideEnd),
          );
        });
    }
  }

  /// Determines whether [expression] is side effect free, under certain
  /// presumptions.
  ///
  /// The presumptions are:
  /// - A getter invocation is presumed to be side effect free, because (a) in
  ///   practice, most getter invocations are side effect free, and (b) it would
  ///   take a lot of analysis to establish with certainty whether a particular
  ///   getter invocation is side effect free.
  /// - A use of a non-null assertion (`!`) or cast (`as`) is presumed to be
  ///   side effect free, because in practice these constructs are only used
  ///   when their operand is already known by the user to be of the appropriate
  ///   type. This enables dead code like `if (a.b!.c == null) { ... }` to be
  ///   eliminated (assuming `c` has a non-null type).
  ///
  /// These assumptions aren't necessarily going to be true of all code. We rely
  /// on the user to verify these assumptions by inspecting the results of dead
  /// code removal.
  bool _looksSideEffectFree(Expression expression) {
    switch (expression) {
      case AsExpression(:var expression):
        // A cast is presumed to be side effect free (provided that its operand
        // is).
        return _looksSideEffectFree(expression);
      case BinaryExpression(:var leftOperand, :var rightOperand):
        return _looksSideEffectFree(leftOperand) &&
            _looksSideEffectFree(rightOperand);
      case SimpleIdentifier():
        // A simple identifier might be a local variable reference or a method
        // tear-off, in which case it's definitely side effect free. Or it might
        // be a call to a getter, in which case we assume it's side effect free.
        return true;
      case Literal():
        return true;
      case ParenthesizedExpression(:var expression):
        return _looksSideEffectFree(expression);
      case PostfixExpression(
        :var operand,
        operator: Token(type: TokenType.BANG),
      ):
        // A non-null assertion is presumed to be side effect free (provided
        // that its operand is).
        return _looksSideEffectFree(operand);
      case PrefixedIdentifier(prefix: Expression? target):
      case PropertyAccess(:var target):
        // If the target isn't side effect free, then the property access isn't.
        if (target != null && !_looksSideEffectFree(target)) return false;
        // A property access might be a method tear-off, in which case it's
        // definitely side effect free. Or it might be a call to a getter, in
        // which case we assume it's side effect free.
        return true;
      case SuperExpression():
        return true;
      default:
        // Anything else is conservatively assumed to have side effects.
        return false;
    }
  }

  /// In the case where the dead code range starts somewhere inside
  /// [partiallyDeadNode], and may continue past it, removes any code after
  /// [partiallyDeadNode] that is included in the dead code range.
  Future<void> _removeDeadCodeAfter({
    required AstNode partiallyDeadNode,
  }) async {
    var parent = partiallyDeadNode.parent;
    switch (parent) {
      case null:
        // No further code after `deadNode`, so nothing else to do.
        return;
      case DoStatement(
            :var doKeyword,
            :var body,
            :var whileKeyword,
            :var semicolon,
            :var end,
            :var hasBreakStatement,
          )
          when body == partiallyDeadNode && _errorEnd >= end:
        if (hasBreakStatement) {
          // It's not safe to remove the `do` statement, because then the
          // `break` might change its meaning.
          // TODO(asashour): consider modifying the do statement to a label
          // https://github.com/dart-lang/sdk/issues/49091#issuecomment-1135489675
          return;
        }
        // The `do` statement's condition is dead too (this means the `do`
        // statement has no reachable `break` statements in it). So the `do`
        // and `while (...);` parts of the `do` statement can be removed, with
        // certain caveats.
        switch (partiallyDeadNode) {
          case Block(:var leftBracket, :var rightBracket):
            // The `do` statement's body is a block, so remove `do {` and
            // `} while (...);`.
            await _addEdit((builder) {
              _deleteLineRange(builder, range.startEnd(doKeyword, leftBracket));
              _deleteLineRange(
                builder,
                range.startEnd(rightBracket, semicolon),
              );
            });
          default:
            // Caveats have been taken care of, so remove `do` and
            // `while (...);`.
            await _addEdit((builder) {
              builder.addDeletion(range.startStart(doKeyword, doKeyword.next!));
              _deleteLineRange(
                builder,
                range.startEnd(whileKeyword, semicolon),
              );
            });
        }
    }
  }

  Future<void> _removeStatement(Statement statement) async {
    var parent = statement.parent;
    switch (parent) {
      case Block():
        await _addEdit((builder) {
          _deleteLineRange(builder, range.entity(statement));
        });
      case IfStatement(:var thenStatement, :var elseStatement)
          when statement == elseStatement:
        // The code looks something like:
        //   if (condition) live; else if (false) dead;
        //    thenStatement-^^^^^      ^^^^^^^^^^^^^^^^-elseStatement
        //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^-parent
        // So drop the `else` and the `elseStatement` to produce:
        //   if (condition) live;
        await _addEdit((builder) {
          builder.addDeletion(range.endEnd(thenStatement, parent));
        });
      default:
        // In general it's not safe to just remove a statement, since it affects
        // how the surrounding code will be parsed. So don't generate a
        // correction.
        break;
    }
  }

  Future<void> _replaceStatementWithInnerStatement(
    Statement statement,
    Statement innerStatement,
  ) async {
    var parent = statement.parent;
    if (parent is Block && innerStatement is Block) {
      // The code looks something like:
      //   { ... if (condition) { live; } ... }
      //                        ^^^^^^^^^-innerStatement
      //         ^^^^^^^^^^^^^^^^^^^^^^^^-statement
      //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^-parent
      // So drop the opening and closing brace of `innerStatement` to produce:
      //   { ...                  live;   ... }
      await _addEdit((builder) {
        _deleteLineRange(
          builder,
          range.startEnd(statement, innerStatement.leftBracket),
        );
        _deleteLineRange(
          builder,
          range.startEnd(innerStatement.rightBracket, statement),
        );
      });
    } else {
      // Don't do anything special with braces. Just replace `statement` with
      // `innerStatement`.
      await _addEdit((builder) {
        builder.addDeletion(range.startStart(statement, innerStatement));
        builder.addDeletion(range.endEnd(innerStatement, statement));
      });
    }
  }
}
