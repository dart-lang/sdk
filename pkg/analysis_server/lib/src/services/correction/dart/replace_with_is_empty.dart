// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithIsEmpty extends ResolvedCorrectionProducer {
  @override
  final FixKind fixKind;

  @override
  final FixKind multiFixKind;

  final BinaryExpression? _binary;

  final _Replacement? _replacement;

  factory ReplaceWithIsEmpty({required CorrectionProducerContext context}) {
    if (context is StubCorrectionProducerContext) {
      return ReplaceWithIsEmpty._(
        context: context,
        fixKind: DartFixKind.replaceWithIsEmpty,
        multiFixKind: DartFixKind.replaceWithIsEmptyMulti,
        binary: null,
        replacement: null,
      );
    }
    var binary = context.node.thisOrAncestorOfType<BinaryExpression>();
    var replacement = _analyzeBinaryExpression(binary);
    FixKind fixKind;
    FixKind multiFixKind;
    if (replacement == null) {
      fixKind = DartFixKind.replaceWithIsEmpty;
      multiFixKind = DartFixKind.replaceWithIsEmptyMulti;
    } else {
      fixKind = replacement.fixKind;
      multiFixKind = replacement.multiFixKind;
    }

    return ReplaceWithIsEmpty._(
      context: context,
      fixKind: fixKind,
      multiFixKind: multiFixKind,
      binary: binary,
      replacement: replacement,
    );
  }

  ReplaceWithIsEmpty._({
    required super.context,
    required this.fixKind,
    required this.multiFixKind,
    required BinaryExpression? binary,
    required _Replacement? replacement,
  }) : _binary = binary,
       _replacement = replacement;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var binary = _binary;
    var replacement = _replacement;
    if (binary == null || replacement == null) {
      return;
    }

    // Skip nullable targets.
    if (replacement.lengthTarget.staticType?.nullabilitySuffix ==
        NullabilitySuffix.question) {
      return;
    }

    var target = utils.getNodeText(replacement.lengthTarget);
    var getter = replacement.getter;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(binary), '$target.$getter');
    });
  }

  static _Replacement? _analyzeBinaryExpression(BinaryExpression? binary) {
    if (binary == null) return null;

    var operator = binary.operator.type;
    var rightValue = _getIntValue(binary.rightOperand);
    if (rightValue != null) {
      var lengthTarget = _getLengthTarget(binary.leftOperand);
      if (lengthTarget == null) {
        return null;
      }
      if (rightValue == 0) {
        if (operator == TokenType.EQ_EQ || operator == TokenType.LT_EQ) {
          return _Replacement.isEmpty(lengthTarget);
        } else if (operator == TokenType.GT || operator == TokenType.BANG_EQ) {
          return _Replacement.isNotEmpty(lengthTarget);
        }
      } else if (rightValue == 1) {
        // 'length >= 1' is same as 'isNotEmpty',
        // and 'length < 1' is same as 'isEmpty'
        if (operator == TokenType.GT_EQ) {
          return _Replacement.isNotEmpty(lengthTarget);
        } else if (operator == TokenType.LT) {
          return _Replacement.isEmpty(lengthTarget);
        }
      }
    } else {
      var leftValue = _getIntValue(binary.leftOperand);
      if (leftValue != null) {
        var lengthTarget = _getLengthTarget(binary.rightOperand);
        if (lengthTarget == null) {
          return null;
        }
        if (leftValue == 0) {
          if (operator == TokenType.EQ_EQ || operator == TokenType.GT_EQ) {
            return _Replacement.isEmpty(lengthTarget);
          } else if (operator == TokenType.LT ||
              operator == TokenType.BANG_EQ) {
            return _Replacement.isNotEmpty(lengthTarget);
          }
        } else if (leftValue == 1) {
          // '1 <= length' is same as 'isNotEmpty',
          // and '1 > length' is same as 'isEmpty'
          if (operator == TokenType.LT_EQ) {
            return _Replacement.isNotEmpty(lengthTarget);
          } else if (operator == TokenType.GT) {
            return _Replacement.isEmpty(lengthTarget);
          }
        }
      }
    }
    return null;
  }

  /// Return the value of an integer literal or prefix expression with a
  /// minus and then an integer literal. For anything else, returns `null`.
  static int? _getIntValue(Expression expressions) {
    // Copied from package:linter/src/rules/prefer_is_empty.dart.
    if (expressions is IntegerLiteral) {
      return expressions.value;
    } else if (expressions is PrefixExpression) {
      var operand = expressions.operand;
      if (expressions.operator.type == TokenType.MINUS &&
          operand is IntegerLiteral) {
        var value = operand.value;
        if (value != null) {
          return -value;
        }
      }
    }
    return null;
  }

  /// Return the expression producing the object on which `length` is being
  /// invoked, or `null` if there is no such expression.
  static Expression? _getLengthTarget(Expression expression) {
    if (expression is PropertyAccess &&
        expression.propertyName.name == 'length') {
      return expression.target;
    } else if (expression is PrefixedIdentifier &&
        expression.identifier.name == 'length') {
      return expression.prefix;
    }
    return null;
  }
}

class _Replacement {
  final FixKind fixKind;
  final FixKind multiFixKind;
  final String getter;
  final Expression lengthTarget;

  _Replacement.isEmpty(Expression lengthTarget)
    : this._(
        fixKind: DartFixKind.replaceWithIsEmpty,
        multiFixKind: DartFixKind.replaceWithIsEmptyMulti,
        getter: 'isEmpty',
        lengthTarget: lengthTarget,
      );

  _Replacement.isNotEmpty(Expression lengthTarget)
    : this._(
        fixKind: DartFixKind.replaceWithIsNotEmpty,
        multiFixKind: DartFixKind.replaceWithIsNotEmptyMulti,
        getter: 'isNotEmpty',
        lengthTarget: lengthTarget,
      );

  _Replacement._({
    required this.fixKind,
    required this.multiFixKind,
    required this.getter,
    required this.lengthTarget,
  });
}
