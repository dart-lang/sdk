// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/type_inference/promotion_key_store.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';

import '../mini_ast.dart';
import '../mini_ir.dart';
import '../mini_types.dart';

/// Creates an [Expression] that, when analyzed, will cause [callback] to be
/// passed an [SsaNodeHarness] allowing the test to examine the values of
/// variables' SSA nodes.
Expression getSsaNodes(void Function(SsaNodeHarness) callback) =>
    new _GetSsaNodes(callback, location: computeLocation());

Expression implicitThis_whyNotPromoted(String staticType,
        void Function(Map<Type, NonPromotionReason>) callback) =>
    new _WhyNotPromoted_ImplicitThis(Type(staticType), callback,
        location: computeLocation());

/// Test harness for creating flow analysis tests.  This class implements all
/// the [Operations] needed by flow analysis, as well as other methods needed
/// for testing.
class FlowAnalysisTestHarness extends Harness with FlowModelHelper<Type> {
  @override
  final PromotionKeyStore<Var> promotionKeyStore = PromotionKeyStore();

  @override
  final Type boolType = Type('bool');

  @override
  Operations<Var, Type> get typeOperations => typeAnalyzer.operations;
}

/// Helper class allowing tests to examine the values of variables' SSA nodes.
class SsaNodeHarness {
  final FlowAnalysis<Node, Statement, Expression, Var, Type> _flow;

  SsaNodeHarness(this._flow);

  /// Gets the SSA node associated with [variable] at the current point in
  /// control flow, or `null` if the variable has been write captured.
  SsaNode<Type>? operator [](Var variable) => _flow.ssaNodeForTesting(variable);
}

class _GetExpressionInfo extends Expression {
  final Expression target;

  final void Function(ExpressionInfo<Type>?) callback;

  _GetExpressionInfo(this.target, this.callback, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    target.preVisit(visitor);
  }

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var type =
        h.typeAnalyzer.analyzeExpression(target, h.typeAnalyzer.unknownType);
    h.flow.forwardExpression(this, target);
    callback(h.flow.expressionInfoForTesting(this));
    return new SimpleTypeAnalysisResult<Type>(type: type);
  }
}

class _GetSsaNodes extends Expression {
  final void Function(SsaNodeHarness) callback;

  _GetSsaNodes(this.callback, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    callback(SsaNodeHarness(h.flow));
    h.irBuilder.atom('null', Kind.expression, location: location);
    return SimpleTypeAnalysisResult(type: h.typeAnalyzer.nullType);
  }
}

class _WhyNotPromoted extends Expression {
  final Expression target;

  final void Function(Map<Type, NonPromotionReason>) callback;

  _WhyNotPromoted(this.target, this.callback, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    target.preVisit(visitor);
  }

  @override
  String toString() => '$target (whyNotPromoted)';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var type =
        h.typeAnalyzer.analyzeExpression(target, h.typeAnalyzer.unknownType);
    h.flow.forwardExpression(this, target);
    Type.withComparisonsAllowed(() {
      callback(h.flow.whyNotPromoted(this)());
    });
    return new SimpleTypeAnalysisResult<Type>(type: type);
  }
}

class _WhyNotPromoted_ImplicitThis extends Expression {
  final Type staticType;

  final void Function(Map<Type, NonPromotionReason>) callback;

  _WhyNotPromoted_ImplicitThis(this.staticType, this.callback,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => 'implicit this (whyNotPromoted)';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    Type.withComparisonsAllowed(() {
      callback(h.flow.whyNotPromotedImplicitThis(staticType)());
    });
    h.irBuilder.atom('noop', Kind.expression, location: location);
    return SimpleTypeAnalysisResult(type: h.typeAnalyzer.nullType);
  }
}

extension ExpressionExtensionForFlowAnalysisTesting on ProtoExpression {
  /// Creates an [Expression] that, when analyzed, will behave the same as
  /// `this`, but after visiting it, will cause [callback] to be passed the
  /// [ExpressionInfo] associated with it.  If the expression has no flow
  /// analysis information associated with it, `null` will be passed to
  /// [callback].
  Expression getExpressionInfo(void Function(ExpressionInfo<Type>?) callback) {
    var location = computeLocation();
    return new _GetExpressionInfo(asExpression(location: location), callback,
        location: location);
  }

  /// Creates an [Expression] that, when analyzed, will behave the same as
  /// `this`, but after visiting it, will cause [callback] to be passed the
  /// non-promotion info associated with it.  If the expression has no
  /// non-promotion info, an empty map will be passed to [callback].
  Expression whyNotPromoted(
      void Function(Map<Type, NonPromotionReason>) callback) {
    var location = computeLocation();
    return new _WhyNotPromoted(asExpression(location: location), callback,
        location: location);
  }
}
