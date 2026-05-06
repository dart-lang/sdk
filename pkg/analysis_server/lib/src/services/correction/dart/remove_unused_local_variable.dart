// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/object.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedLocalVariable extends ResolvedCorrectionProducer {
  final List<_Command> _commands = [];

  RemoveUnusedLocalVariable({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Not predictably the correct action.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.removeUnusedLocalVariable;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var applyCommands = true;
    applyCommands &= _deleteDeclaration();
    applyCommands &= _deleteReferences();

    if (!applyCommands) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      for (var command in _commands) {
        command.execute(builder);
      }
    });
  }

  /// Adds some or all of [ranges] to [deletedRanges], if they are valid
  /// additions.
  ///
  /// If any range in [ranges] is covered by one of the deleted ranges, it is
  /// not added. If any range intersects with one of the deleted ranges,
  /// returns `false`, and no ranges are added.
  bool _addReferenceRanges(
    List<SourceRange> ranges,
    List<SourceRange> deletedRanges,
  ) {
    var rangesToAdd = <SourceRange>[];
    for (var range in ranges) {
      var isCovered = false;
      for (var other in deletedRanges) {
        if (other.covers(range)) {
          isCovered = true;
          break;
        } else if (other.intersects(range)) {
          return false;
        }
      }

      if (!isCovered) {
        rangesToAdd.add(range);
      }
    }

    for (var range in rangesToAdd) {
      _commands.add(_DeleteSourceRangeCommand(sourceRange: range));
      deletedRanges.add(range);
    }

    return true;
  }

  bool _deleteDeclaration() {
    var element = _localVariableElement();
    if (element == null) {
      return false;
    }
    switch (node) {
      case VariableDeclaration():
        var declarationList = node.parent;
        if (declarationList is! VariableDeclarationList) return false;
        var declarationStatement = declarationList.parent;
        if (declarationStatement is! VariableDeclarationStatement) return false;
        if (declarationList.variables.length != 1) {
          _commands.add(
            _DeleteNodeInListCommand(
              nodes: declarationList.variables,
              node: node,
            ),
          );
        } else {
          var initializer = declarationList.variables.first.initializer;
          var unParenthesized = initializer?.unParenthesized;
          if (unParenthesized != null &&
              _hasSideEffect(unParenthesized, element)) {
            if (unParenthesized is AsExpression) {
              _commands.add(
                _DeleteSourceRangeCommand(
                  sourceRange: range.startStart(
                    declarationStatement,
                    unParenthesized.expression,
                  ),
                ),
              );
              _commands.add(
                _DeleteSourceRangeCommand(
                  sourceRange: range.endEnd(
                    unParenthesized.expression,
                    unParenthesized,
                  ),
                ),
              );
            } else {
              _commands.add(
                _DeleteSourceRangeCommand(
                  sourceRange: SourceRange(
                    declarationStatement.offset,
                    initializer!.offset - declarationStatement.offset,
                  ),
                ),
              );
            }
          } else {
            _commands.add(
              _DeleteStatementCommand(
                utils: utils,
                statement: declarationStatement,
              ),
            );
          }
        }
        return true;

      case DeclaredVariablePattern declaredVariable:
        switch (node.parent) {
          case ListPattern _:
          case MapPatternEntry _:
            return _deleteDeclarationInContainerPattern(
              declaredVariable: declaredVariable,
            );
          case LogicalAndPattern logicalAnd:
            return _deleteDeclarationInLogicalAndPattern(
              declaredVariable: declaredVariable,
              logicalAnd: logicalAnd,
            );
          case PatternField patternField:
            return _deleteDeclarationInPatternField(
              patternField: patternField,
              declaredVariable: declaredVariable,
            );
        }
    }

    // We don't know the declaration, disable the fix.
    return false;
  }

  bool _deleteDeclarationInContainerPattern({
    required DeclaredVariablePattern declaredVariable,
  }) {
    String replacement;
    if (declaredVariable.type case var typeNode?) {
      var typeStr = utils.getNodeText(typeNode);
      replacement = '$typeStr _';
    } else {
      replacement = '_';
    }
    _commands.add(
      _ReplaceSourceRangeCommand(
        sourceRange: range.node(declaredVariable),
        replacement: replacement,
      ),
    );
    return true;
  }

  bool _deleteDeclarationInLogicalAndPattern({
    required DeclaredVariablePattern declaredVariable,
    required LogicalAndPattern logicalAnd,
  }) {
    if (declaredVariable.type case var typeNode?) {
      var typeStr = utils.getNodeText(typeNode);
      _commands.add(
        _ReplaceSourceRangeCommand(
          sourceRange: range.node(declaredVariable),
          replacement: '$typeStr _',
        ),
      );
    } else if (logicalAnd.leftOperand == declaredVariable) {
      _commands.add(
        _DeleteSourceRangeCommand(
          sourceRange: range.startStart(
            declaredVariable,
            logicalAnd.rightOperand,
          ),
        ),
      );
    } else {
      _commands.add(
        _DeleteSourceRangeCommand(
          sourceRange: range.endEnd(logicalAnd.leftOperand, declaredVariable),
        ),
      );
    }
    return true;
  }

  bool _deleteDeclarationInPatternField({
    required DeclaredVariablePattern declaredVariable,
    required PatternField patternField,
  }) {
    switch (patternField.parent) {
      case ObjectPatternImpl objectPattern:
        var nameNode = patternField.name;
        if (nameNode == null) {
          return false;
        }

        var fields = objectPattern.fields;
        // Remove completely `var A(:notUsed) = x;`
        if (fields.length == 1) {
          var patternDeclaration = objectPattern.parent;
          if (patternDeclaration is PatternVariableDeclarationImpl) {
            var patternStatement = patternDeclaration.parent;
            if (patternStatement is PatternVariableDeclarationStatementImpl) {
              _commands.add(
                _DeleteStatementCommand(
                  utils: utils,
                  statement: patternStatement,
                ),
              );
              return true;
            }
          }
        }
        // If matching, the explicit type is used.
        if (declaredVariable.type != null) {
          var patternContext = objectPattern.patternContext;
          if (patternContext is GuardedPattern) {
            if (nameNode.name == null) {
              _commands.add(
                _AddExplicitFieldNameCommand(
                  declaredVariable: declaredVariable,
                  nameNode: nameNode,
                ),
              );
            }
            _commands.add(
              _MakeItWildcardCommand(declaredVariable: declaredVariable),
            );
            return true;
          }
        }
        // Remove a single field.
        _commands.add(
          _DeleteNodeInListCommand(nodes: fields, node: patternField),
        );
        return true;
      case RecordPattern():
        var nameNode = patternField.name;
        if (nameNode != null && nameNode.name == null) {
          _commands.add(
            _AddExplicitFieldNameCommand(
              declaredVariable: declaredVariable,
              nameNode: nameNode,
            ),
          );
        }
        _commands.add(
          _MakeItWildcardCommand(declaredVariable: declaredVariable),
        );
        return true;
    }

    // We don't know the declaration, disable the fix.
    return false;
  }

  bool _deleteReferences() {
    var element = _localVariableElement();
    if (element == null) {
      return false;
    }

    var node = this.node;
    var functionBody = node.thisOrAncestorOfType<FunctionBody>();
    if (functionBody == null) {
      return false;
    }

    var references = findLocalElementReferences(functionBody, element);

    var deletedRanges = <SourceRange>[];

    for (var reference in references) {
      var referenceRanges = _referenceRangesToDelete(reference, element);
      if (referenceRanges == null) {
        return false;
      }

      if (!_addReferenceRanges(referenceRanges, deletedRanges)) {
        return false;
      }
    }

    return true;
  }

  List<SourceRange>? _forAssignmentExpression(
    AssignmentExpression node,
    LocalVariableElement element,
  ) {
    var parent = node.parent!;
    if (parent is ArgumentList) {
      return [range.startStart(node, node.operator.next!)];
    }

    var unParenthesized = node.rightHandSide.unParenthesized;
    if (_hasSideEffect(unParenthesized, element)) {
      if (unParenthesized is AssignmentExpression) {
        return [
          range.startStart(parent, unParenthesized),
          range.endEnd(unParenthesized, node),
        ];
      }

      if (unParenthesized is AsExpression) {
        return [
          range.startStart(parent, unParenthesized.expression),
          range.endEnd(unParenthesized.expression, unParenthesized),
        ];
      }

      return [range.startStart(node, node.rightHandSide)];
    }

    return [utils.getLinesRange(range.node(parent))];
  }

  /// Returns whether [node] may reasonably be assumed to have side effects.
  ///
  /// In the case of an [AssignmentExpression], [element] is used to determine
  /// whether [node] has side effects _other than_ assigning to [element].
  bool _hasSideEffect(Expression node, LocalVariableElement element) {
    var visitor = _SideEffectVisitor(element);
    node.accept(visitor);
    return visitor.hasSideEffect;
  }

  LocalVariableElement? _localVariableElement() {
    var node = this.node;
    if (node is DeclaredVariablePattern) {
      return node.declaredFragment?.element;
    } else if (node is VariableDeclaration) {
      if (node.name == token) {
        return node.declaredFragment?.element.ifTypeOrNull();
      }
    }
    return null;
  }

  List<SourceRange>? _referenceRangesToDelete(
    AstNode reference,
    LocalVariableElement element,
  ) {
    var parent = reference.parent;
    if (parent is AssignmentExpression) {
      if (parent.leftHandSide == reference) {
        return _forAssignmentExpression(parent, element);
      }
    }
    return null;
  }
}

class _AddExplicitFieldNameCommand extends _Command {
  final DeclaredVariablePattern declaredVariable;
  final PatternFieldName nameNode;

  _AddExplicitFieldNameCommand({
    required this.declaredVariable,
    required this.nameNode,
  });

  @override
  void execute(DartFileEditBuilder builder) {
    builder.addSimpleReplacement(
      range.startStart(nameNode.colon, declaredVariable),
      '${declaredVariable.name.lexeme}: ',
    );
  }
}

abstract class _Command {
  void execute(DartFileEditBuilder builder);
}

class _DeleteNodeInListCommand<T extends AstNode> extends _Command {
  final NodeList<T> nodes;
  final T node;

  _DeleteNodeInListCommand({required this.nodes, required this.node});

  @override
  void execute(DartFileEditBuilder builder) {
    var sourceRange = range.nodeInList(nodes, node);
    builder.addDeletion(sourceRange);
  }
}

class _DeleteSourceRangeCommand extends _Command {
  final SourceRange sourceRange;

  _DeleteSourceRangeCommand({required this.sourceRange});

  @override
  void execute(DartFileEditBuilder builder) {
    builder.addDeletion(sourceRange);
  }
}

class _DeleteStatementCommand extends _Command {
  final CorrectionUtils utils;
  final Statement statement;

  _DeleteStatementCommand({required this.utils, required this.statement});

  @override
  void execute(DartFileEditBuilder builder) {
    var statementRange = range.node(statement);
    var linesRange = utils.getLinesRange(statementRange);
    builder.addDeletion(linesRange);
  }
}

class _MakeItWildcardCommand extends _Command {
  final DeclaredVariablePattern declaredVariable;

  _MakeItWildcardCommand({required this.declaredVariable});

  @override
  void execute(DartFileEditBuilder builder) {
    var nameRange = range.token(declaredVariable.name);
    builder.addSimpleReplacement(nameRange, '_');
  }
}

class _ReplaceSourceRangeCommand extends _Command {
  final SourceRange sourceRange;
  final String replacement;

  _ReplaceSourceRangeCommand({
    required this.sourceRange,
    required this.replacement,
  });

  @override
  void execute(DartFileEditBuilder builder) {
    builder.addSimpleReplacement(sourceRange, replacement);
  }
}

class _SideEffectVisitor extends RecursiveAstVisitor<void> {
  final LocalVariableElement element;
  bool hasSideEffect = false;

  _SideEffectVisitor(this.element);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (hasSideEffect) return;
    var lhs = node.leftHandSide.unParenthesized;
    if (lhs is Identifier && lhs.element == element) {
      node.rightHandSide.accept(this);
    } else {
      hasSideEffect = true;
    }
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    hasSideEffect = true;
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    hasSideEffect = true;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    hasSideEffect = true;
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (hasSideEffect) return;
    if (node.operator.type == TokenType.PLUS_PLUS ||
        node.operator.type == TokenType.MINUS_MINUS) {
      var operand = node.operand.unParenthesized;
      if (operand is Identifier && operand.element == element) {
        // Not a side effect.
      } else {
        hasSideEffect = true;
      }
    } else {
      super.visitPostfixExpression(node);
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (hasSideEffect) return;
    if (node.operator.type == TokenType.PLUS_PLUS ||
        node.operator.type == TokenType.MINUS_MINUS) {
      var operand = node.operand.unParenthesized;
      if (operand is Identifier && operand.element == element) {
        // Not a side effect.
      } else {
        hasSideEffect = true;
      }
    } else {
      super.visitPrefixExpression(node);
    }
  }
}
