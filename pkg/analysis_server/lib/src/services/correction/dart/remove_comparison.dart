// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/error/codes.g.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveComparison extends CorrectionProducer {
  @override
  final FixKind fixKind;

  @override
  final FixKind multiFixKind;

  /// Initialize a newly created instance with [DartFixKind.REMOVE_COMPARISON].
  RemoveComparison()
      : fixKind = DartFixKind.REMOVE_COMPARISON,
        multiFixKind = DartFixKind.REMOVE_COMPARISON_MULTI;

  /// Initialize a newly created instance with [DartFixKind.REMOVE_TYPE_CHECK].
  RemoveComparison.typeCheck()
      : fixKind = DartFixKind.REMOVE_TYPE_CHECK,
        multiFixKind = DartFixKind.REMOVE_TYPE_CHECK_MULTI;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  /// Return `true` if the condition will always return `false`.
  bool get _conditionIsFalse {
    var errorCode = (diagnostic as AnalysisError).errorCode;
    return errorCode == WarningCode.UNNECESSARY_NAN_COMPARISON_FALSE ||
        errorCode == WarningCode.UNNECESSARY_NULL_COMPARISON_FALSE ||
        errorCode == WarningCode.UNNECESSARY_TYPE_CHECK_FALSE;
  }

  /// Return `true` if the condition will always return `true`.
  bool get _conditionIsTrue {
    var errorCode = (diagnostic as AnalysisError).errorCode;
    return errorCode == WarningCode.UNNECESSARY_NAN_COMPARISON_TRUE ||
        errorCode == WarningCode.UNNECESSARY_NULL_COMPARISON_TRUE ||
        errorCode == WarningCode.UNNECESSARY_TYPE_CHECK_TRUE ||
        errorCode.name == LintNames.avoid_null_checks_in_equality_operators;
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parent = node.parent;
    if (parent is AssertInitializer && _conditionIsTrue) {
      var constructor = parent.parent as ConstructorDeclaration;
      var list = constructor.initializers;
      if (list.length == 1) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.endEnd(constructor.parameters, parent));
        });
      } else {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.nodeInList(list, parent));
        });
      }
    } else if (parent is AssertStatement && _conditionIsTrue) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(utils.getLinesRange(range.node(parent)));
      });
    } else if (parent is BinaryExpression) {
      var type = parent.operator.type;
      if ((type == TokenType.AMPERSAND_AMPERSAND && _conditionIsTrue) ||
          (type == TokenType.BAR_BAR && _conditionIsFalse)) {
        await _removeOperatorAndOperand(builder, parent);
      }
    } else if (parent is IfElement) {
      await _ifElement(parent, builder);
    } else if (parent is IfStatement) {
      if (parent.elseStatement == null && _conditionIsTrue) {
        await _ifStatement(parent, builder);
      }
    }
  }

  Future<void> _ifElement(IfElement node, ChangeBuilder builder) async {
    if (_conditionIsTrue) {
      await builder.addDartFileEdit(file, (builder) {
        final text = _textWithLeadingComments(node.thenElement);
        final unIndented = utils.indentLeft(text);
        builder.addSimpleReplacement(range.node(node), unIndented);
      });
    } else if (_conditionIsFalse) {
      final elseElement = node.elseElement;
      if (elseElement != null) {
        await builder.addDartFileEdit(file, (builder) {
          final text = _textWithLeadingComments(elseElement);
          final unIndented = utils.indentLeft(text);
          builder.addSimpleReplacement(range.node(node), unIndented);
        });
      } else {
        final elements = node.parent.containerElements;
        if (elements != null) {
          await builder.addDartFileEdit(file, (builder) {
            final nodeRange = range.nodeInList(elements, node);
            builder.addDeletion(nodeRange);
          });
        }
      }
    }
  }

  Future<void> _ifStatement(IfStatement node, ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      var nodeRange = utils.getLinesRangeStatements([node]);

      String bodyCode;
      var body = node.thenStatement;
      if (body is Block) {
        var statements = body.statements;
        if (statements.isEmpty) {
          builder.addDeletion(nodeRange);
          return;
        } else {
          bodyCode = utils.getRangeText(
            utils.getLinesRangeStatements(statements),
          );
        }
      } else {
        bodyCode = utils.getRangeText(
          utils.getLinesRangeStatements([body]),
        );
      }

      bodyCode = utils.indentSourceLeftRight(bodyCode);
      builder.addSimpleReplacement(nodeRange, bodyCode);
    });
  }

  /// Use the [builder] to add an edit to delete the operator and given
  /// [operand] from the [binary] expression.
  Future<void> _removeOperatorAndOperand(
      ChangeBuilder builder, BinaryExpression binary) async {
    SourceRange operatorAndOperand;
    if (binary.leftOperand == node) {
      operatorAndOperand = range.startStart(node, binary.rightOperand);
    } else {
      operatorAndOperand = range.endEnd(binary.leftOperand, node);
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(operatorAndOperand);
    });
  }

  String _textWithLeadingComments(AstNode node) {
    return utils.getNodeText(node, withLeadingComments: true);
  }
}

extension on AstNode? {
  NodeList<AstNode>? get containerElements {
    final self = this;
    if (self is ListLiteral) {
      return self.elements;
    } else if (self is SetOrMapLiteral) {
      return self.elements;
    }
    return null;
  }
}
