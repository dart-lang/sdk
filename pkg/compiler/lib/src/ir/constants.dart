// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/src/printer.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'package:front_end/src/api_prototype/constant_evaluator.dart' as ir;
import 'package:front_end/src/api_unstable/dart2js.dart' as ir;

import '../kernel/dart2js_target.dart';

typedef ReportErrorFunction = void Function(
    ir.LocatedMessage message, List<ir.LocatedMessage> context);

class Dart2jsConstantEvaluator extends ir.ConstantEvaluator {
  final bool _supportReevaluationForTesting;

  bool requiresConstant;

  Dart2jsConstantEvaluator(
      ir.TypeEnvironment typeEnvironment, ReportErrorFunction reportError,
      {Map<String, String> environment: const {},
      bool enableTripleShift = false,
      bool supportReevaluationForTesting: false,
      ir.EvaluationMode evaluationMode})
      : _supportReevaluationForTesting = supportReevaluationForTesting,
        assert(evaluationMode != null),
        super(
            const Dart2jsConstantsBackend(supportsUnevaluatedConstants: false),
            environment,
            typeEnvironment,
            new ErrorReporter(reportError),
            enableTripleShift: enableTripleShift,
            evaluationMode: evaluationMode);

  @override
  ErrorReporter get errorReporter => super.errorReporter;

  /// Evaluates [node] to a constant in the given [staticTypeContext].
  ///
  /// If [requireConstant] is `true`, an error is reported if [node] is not
  /// a valid constant. Otherwise, `null` if [node] is not a valid constant.
  ///
  /// If [replaceImplicitConstant] is `true`, if [node] is not a constant
  /// expression but evaluates to a constant, [node] is replaced with an
  /// [ir.ConstantExpression] holding the constant. Otherwise the [node] is not
  /// replaced even when it evaluated to a constant.
  @override
  ir.Constant evaluate(
      ir.StaticTypeContext staticTypeContext, ir.Expression node,
      {ir.TreeNode contextNode,
      bool requireConstant: true,
      bool replaceImplicitConstant: true}) {
    errorReporter.requiresConstant = requireConstant;
    if (node is ir.ConstantExpression) {
      ir.Constant constant = node.constant;
      if (constant is ir.UnevaluatedConstant) {
        ir.Constant result = super.evaluate(
            staticTypeContext, constant.expression,
            contextNode: contextNode);
        assert(
            result is ir.UnevaluatedConstant ||
                !result.accept(const UnevaluatedConstantFinder()),
            "Invalid constant result $result from ${constant.expression}.");
        if (!_supportReevaluationForTesting) {
          node.constant = result;
        }
        return result;
      }
      return constant;
    }
    if (requireConstant) {
      return super.evaluate(staticTypeContext, node, contextNode: contextNode);
    } else {
      try {
        ir.Constant constant =
            super.evaluate(staticTypeContext, node, contextNode: contextNode);
        if (constant is ir.UnevaluatedConstant &&
            constant.expression is ir.InvalidExpression) {
          return null;
        }
        if (constant != null && replaceImplicitConstant) {
          // Note: Using [replaceWith] is slow and should be avoided.
          node.replaceWith(ir.ConstantExpression(
              constant, node.getStaticType(staticTypeContext))
            ..fileOffset = node.fileOffset);
        }
        return constant;
      } catch (e) {
        return null;
      }
    }
  }
}

class ErrorReporter implements ir.ErrorReporter {
  final ReportErrorFunction _reportError;
  bool requiresConstant;

  ErrorReporter(this._reportError);

  @override
  void reportInvalidExpression(ir.InvalidExpression node) {
    // Ignore.
  }

  @override
  void report(ir.LocatedMessage message, List<ir.LocatedMessage> context) {
    if (requiresConstant) {
      _reportError(message, context);
    }
  }
}

/// [ir.Constant] visitor that returns `true` if the visitor constant contains
/// an [ir.UnevaluatedConstant].
class UnevaluatedConstantFinder extends ir.ConstantVisitor<bool> {
  const UnevaluatedConstantFinder();

  @override
  bool defaultConstant(ir.Constant node) => false;

  @override
  bool visitUnevaluatedConstant(ir.UnevaluatedConstant node) => true;

  @override
  bool visitPartialInstantiationConstant(ir.PartialInstantiationConstant node) {
    return node.tearOffConstant.accept(this);
  }

  @override
  bool visitInstanceConstant(ir.InstanceConstant node) {
    for (ir.Constant value in node.fieldValues.values) {
      if (value.accept(this)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitSetConstant(ir.SetConstant node) {
    for (ir.Constant value in node.entries) {
      if (value.accept(this)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitListConstant(ir.ListConstant node) {
    for (ir.Constant value in node.entries) {
      if (value.accept(this)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitMapConstant(ir.MapConstant node) {
    for (ir.ConstantMapEntry entry in node.entries) {
      if (entry.key.accept(this)) {
        return true;
      }
      if (entry.value.accept(this)) {
        return true;
      }
    }
    return false;
  }
}

/// Class to represent a reference to a constant in allocation nodes.
///
/// This class is needed in order to support serialization of references to
/// constant nodes. Since the constant nodes are not [ir.TreeNode]s we can only
/// serialize the constants as values which would bypass by the canonicalization
/// performed by the CFE. This class extends only as a trick to easily pass
/// it through serialization.
///
/// By adding a reference to the constant expression in which the constant
/// occurred, we can serialize references to constants in two steps: a reference
/// to the constant expression followed by an index of the referred constant
/// in the traversal order of the constant held by the constant expression.
///
/// This is used for list, map, and set literals.
class ConstantReference extends ir.TreeNode {
  final ir.ConstantExpression expression;
  final ir.Constant constant;

  ConstantReference(this.expression, this.constant);

  @override
  void visitChildren(ir.Visitor v) {
    throw new UnsupportedError("ConstantReference.visitChildren");
  }

  @override
  R accept<R>(ir.TreeVisitor<R> v) {
    throw new UnsupportedError("ConstantReference.accept");
  }

  @override
  transformChildren(ir.Transformer v) {
    throw new UnsupportedError("ConstantReference.transformChildren");
  }

  @override
  int get hashCode => 13 * constant.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConstantReference && constant == other.constant;
  }

  @override
  String toString() => 'ConstantReference(${toStringInternal()})';

  @override
  String toStringInternal() => 'constant=${constant.toStringInternal()}';

  @override
  String toText(ir.AstTextStrategy strategy) => constant.toText(strategy);

  @override
  void toTextInternal(ir.AstPrinter printer) =>
      constant.toTextInternal(printer);
}
