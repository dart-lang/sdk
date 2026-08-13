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

  factory({required CorrectionProducerContext context}) {
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

  new _({
    required super.context,
    required this.fixKind,
    required this.multiFixKind,
    required this._binary,
    required this._replacement,
  });

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
    var lengthAccess = replacement.lengthAccess;
    if (lengthAccess.target.staticType?.nullabilitySuffix ==
        NullabilitySuffix.question) {
      return;
    }

    // Keep everything through the period so that comments between the target
    // and `length` remain attached to the replacement getter.
    var target = utils.getRangeText(
      range.startStart(lengthAccess.target, lengthAccess.length),
    );
    var getter = replacement.getter;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(binary), '$target$getter');
    });
  }

  static _Replacement? _analyzeBinaryExpression(BinaryExpression? binary) {
    if (binary == null) return null;

    var operator = binary.operator.type;
    var rightValue = _getIntValue(binary.rightOperand);
    if (rightValue != null) {
      var lengthAccess = _getLengthAccess(binary.leftOperand);
      if (lengthAccess == null) {
        return null;
      }
      if (rightValue == 0) {
        if (operator == TokenType.EQ_EQ || operator == TokenType.LT_EQ) {
          return _Replacement.isEmpty(lengthAccess);
        } else if (operator == TokenType.GT || operator == TokenType.BANG_EQ) {
          return _Replacement.isNotEmpty(lengthAccess);
        }
      } else if (rightValue == 1) {
        // 'length >= 1' is same as 'isNotEmpty',
        // and 'length < 1' is same as 'isEmpty'
        if (operator == TokenType.GT_EQ) {
          return _Replacement.isNotEmpty(lengthAccess);
        } else if (operator == TokenType.LT) {
          return _Replacement.isEmpty(lengthAccess);
        }
      }
    } else {
      var leftValue = _getIntValue(binary.leftOperand);
      if (leftValue != null) {
        var lengthAccess = _getLengthAccess(binary.rightOperand);
        if (lengthAccess == null) {
          return null;
        }
        if (leftValue == 0) {
          if (operator == TokenType.EQ_EQ || operator == TokenType.GT_EQ) {
            return _Replacement.isEmpty(lengthAccess);
          } else if (operator == TokenType.LT ||
              operator == TokenType.BANG_EQ) {
            return _Replacement.isNotEmpty(lengthAccess);
          }
        } else if (leftValue == 1) {
          // '1 <= length' is same as 'isNotEmpty',
          // and '1 > length' is same as 'isEmpty'
          if (operator == TokenType.LT_EQ) {
            return _Replacement.isNotEmpty(lengthAccess);
          } else if (operator == TokenType.GT) {
            return _Replacement.isEmpty(lengthAccess);
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

  /// Returns the target and `length` identifier of a `length` access.
  static ({Expression target, SimpleIdentifier length})? _getLengthAccess(
    Expression expression,
  ) {
    switch (expression) {
      case PropertyAccess(target: var target?, propertyName: var length):
        if (length.name == 'length') {
          return (target: target, length: length);
        }
      case PrefixedIdentifier(:var prefix, identifier: var length):
        if (length.name == 'length') {
          return (target: prefix, length: length);
        }
    }
    return null;
  }
}

class _Replacement({
  required final FixKind fixKind,
  required final FixKind multiFixKind,
  required final String getter,
  required final ({Expression target, SimpleIdentifier length}) lengthAccess,
}) {
  new isEmpty(({Expression target, SimpleIdentifier length}) lengthAccess)
    : this(
        fixKind: DartFixKind.replaceWithIsEmpty,
        multiFixKind: DartFixKind.replaceWithIsEmptyMulti,
        getter: 'isEmpty',
        lengthAccess: lengthAccess,
      );

  new isNotEmpty(({Expression target, SimpleIdentifier length}) lengthAccess)
    : this(
        fixKind: DartFixKind.replaceWithIsNotEmpty,
        multiFixKind: DartFixKind.replaceWithIsNotEmptyMulti,
        getter: 'isNotEmpty',
        lengthAccess: lengthAccess,
      );
}
