// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedLocalVariable extends CorrectionProducer {
  final List<_Command> _commands = [];

  @override
  // Not predictably the correct action.
  bool get canBeAppliedInBulk => false;

  @override
  // Not predictably the correct action.
  bool get canBeAppliedToFile => false;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNUSED_LOCAL_VARIABLE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var applyCommands = true;
    applyCommands &= _deleteDeclaration();
    applyCommands &= _deleteReferences();

    if (!applyCommands) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      for (final command in _commands) {
        command.execute(builder);
      }
    });
  }

  bool _deleteDeclaration() {
    switch (node) {
      case VariableDeclaration():
        final declarationList = node.parent;
        if (declarationList is VariableDeclarationList) {
          final declarationStatement = declarationList.parent;
          if (declarationStatement is VariableDeclarationStatement) {
            if (declarationList.variables.length == 1) {
              _commands.add(
                _DeleteStatementCommand(
                  utils: utils,
                  statement: declarationStatement,
                ),
              );
            } else {
              _commands.add(
                _DeleteNodeInListCommand(
                  nodes: declarationList.variables,
                  node: node,
                ),
              );
            }
            return true;
          }
        }
      case DeclaredVariablePattern declaredVariable:
        switch (node.parent) {
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

  bool _deleteDeclarationInLogicalAndPattern({
    required DeclaredVariablePattern declaredVariable,
    required LogicalAndPattern logicalAnd,
  }) {
    if (declaredVariable.type case final typeNode?) {
      final typeStr = utils.getNodeText(typeNode);
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
          sourceRange: range.endEnd(
            logicalAnd.leftOperand,
            declaredVariable,
          ),
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
        final nameNode = patternField.name;
        if (nameNode == null) {
          return false;
        }

        final fields = objectPattern.fields;
        // Remove completely `var A(:notUsed) = x;`
        if (fields.length == 1) {
          final patternDeclaration = objectPattern.parent;
          if (patternDeclaration is PatternVariableDeclaration) {
            final patternStatement = patternDeclaration.parent;
            if (patternStatement is PatternVariableDeclarationStatement) {
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
          final patternContext = objectPattern.patternContext;
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
              _MakeItWildcardCommand(
                declaredVariable: declaredVariable,
              ),
            );
            return true;
          }
        }
        // Remove a single field.
        _commands.add(
          _DeleteNodeInListCommand(
            nodes: fields,
            node: patternField,
          ),
        );
        return true;
      case RecordPattern():
        final nameNode = patternField.name;
        if (nameNode != null && nameNode.name == null) {
          _commands.add(
            _AddExplicitFieldNameCommand(
              declaredVariable: declaredVariable,
              nameNode: nameNode,
            ),
          );
        }
        _commands.add(
          _MakeItWildcardCommand(
            declaredVariable: declaredVariable,
          ),
        );
        return true;
    }

    // We don't know the declaration, disable the fix.
    return false;
  }

  bool _deleteReferences() {
    final element = _localVariableElement();
    if (element is! LocalVariableElement) {
      return false;
    }

    final node = this.node;
    final functionBody = node.thisOrAncestorOfType<FunctionBody>();
    if (functionBody == null) {
      return false;
    }

    final references = findLocalElementReferences(functionBody, element);

    final deletedRanges = <SourceRange>[];

    for (final reference in references) {
      final referenceRange = _referenceRangeToDelete(reference);
      if (referenceRange == null) {
        return false;
      }

      var isCovered = false;
      for (final other in deletedRanges) {
        if (other.covers(referenceRange)) {
          isCovered = true;
          break;
        } else if (other.intersects(referenceRange)) {
          return false;
        }
      }

      if (isCovered) {
        continue;
      }

      _commands.add(
        _DeleteSourceRangeCommand(
          sourceRange: referenceRange,
        ),
      );
      deletedRanges.add(referenceRange);
    }

    return true;
  }

  SourceRange _forAssignmentExpression(AssignmentExpression node) {
    // todo (pq): consider node.parent is! ExpressionStatement to handle
    // assignments in parens, etc.
    var parent = node.parent!;
    if (parent is ArgumentList) {
      return range.startStart(node, node.operator.next!);
    } else {
      return utils.getLinesRange(range.node(parent));
    }
  }

  Element? _localVariableElement() {
    final node = this.node;
    if (node is DeclaredVariablePattern) {
      return node.declaredElement;
    } else if (node is VariableDeclaration) {
      if (node.name == token) {
        return node.declaredElement;
      }
    }
    return null;
  }

  SourceRange? _referenceRangeToDelete(AstNode reference) {
    final parent = reference.parent;
    if (parent is AssignmentExpression) {
      if (parent.leftHandSide == reference) {
        return _forAssignmentExpression(parent);
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

  _DeleteNodeInListCommand({
    required this.nodes,
    required this.node,
  });

  @override
  void execute(DartFileEditBuilder builder) {
    final sourceRange = range.nodeInList(nodes, node);
    builder.addDeletion(sourceRange);
  }
}

class _DeleteSourceRangeCommand extends _Command {
  final SourceRange sourceRange;

  _DeleteSourceRangeCommand({
    required this.sourceRange,
  });

  @override
  void execute(DartFileEditBuilder builder) {
    builder.addDeletion(sourceRange);
  }
}

class _DeleteStatementCommand extends _Command {
  final CorrectionUtils utils;
  final Statement statement;

  _DeleteStatementCommand({
    required this.utils,
    required this.statement,
  });

  @override
  void execute(DartFileEditBuilder builder) {
    final statementRange = range.node(statement);
    final linesRange = utils.getLinesRange(statementRange);
    builder.addDeletion(linesRange);
  }
}

class _MakeItWildcardCommand extends _Command {
  final DeclaredVariablePattern declaredVariable;

  _MakeItWildcardCommand({
    required this.declaredVariable,
  });

  @override
  void execute(DartFileEditBuilder builder) {
    final nameRange = range.token(declaredVariable.name);
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
