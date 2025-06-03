// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_operations.dart';
import 'package:_fe_analyzer_shared/src/type_inference/promotion_key_store.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';

import '../mini_ast.dart';
import '../mini_ir.dart';
import '../mini_types.dart';

/// Creates an [Expression] that, when analyzed, will cause [callback] to be
/// passed an [SsaNodeHarness] allowing the test to examine the values of
/// variables' SSA nodes.
Expression getSsaNodes(void Function(SsaNodeHarness) callback) =>
    new _GetSsaNodes(callback, location: computeLocation());

Expression implicitThis_whyNotPromoted(
  String staticType,
  void Function(Map<SharedTypeView, NonPromotionReason>) callback,
) => new _WhyNotPromoted_ImplicitThis(
  Type(staticType),
  callback,
  location: computeLocation(),
);

/// Test harness for creating flow analysis tests.  This class provides all
/// the [FlowAnalysisOperations] needed by flow analysis, as well as other
/// methods needed for testing.
class FlowAnalysisTestHarness extends Harness
    with FlowModelHelper<SharedTypeView> {
  @override
  final PromotionKeyStore<Var> promotionKeyStore = PromotionKeyStore();

  @override
  final SharedTypeView boolType = SharedTypeView(Type('bool'));

  @override
  TypeAnalyzerOptions get typeAnalyzerOptions => computeTypeAnalyzerOptions();

  @override
  FlowAnalysisOperations<Var, SharedTypeView> get typeOperations =>
      typeAnalyzer.operations;

  @override
  bool isFinal(int variableKey) {
    Var? variable = promotionKeyStore.variableForKey(variableKey);
    if (variable != null && operations.isFinal(variable)) return true;
    return false;
  }

  @override
  bool isValidPromotionStep({
    required SharedTypeView previousType,
    required SharedTypeView newType,
  }) {
    // Caller must ensure that `newType <: previousType`.
    assert(
      typeOperations.isSubtypeOf(newType, previousType),
      "Expected $newType to be a subtype of $previousType.",
    );
    // Promotion to a mutual subtype is not allowed. Since the caller has
    // already ensured that `newType <: previousType`, it's only necessary to
    // check whether `previousType <: newType`.
    return !typeOperations.isSubtypeOf(previousType, newType);
  }
}

/// Helper class allowing tests to examine the values of variables' SSA nodes.
class SsaNodeHarness {
  final FlowAnalysis<Node, Statement, Expression, Var, SharedTypeView> _flow;

  SsaNodeHarness(this._flow);

  /// Gets the SSA node associated with [variable] at the current point in
  /// control flow, or `null` if the variable has been write captured.
  SsaNode<SharedTypeView>? operator [](Var variable) =>
      _flow.ssaNodeForTesting(variable);
}

class _GetExpressionInfo extends Expression {
  final Expression target;

  final void Function(ExpressionInfo<SharedTypeView>?) callback;

  _GetExpressionInfo(this.target, this.callback, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    target.preVisit(visitor);
  }

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var type = h.typeAnalyzer.analyzeExpression(
      target,
      h.operations.unknownType,
    );
    h.flow.forwardExpression(this, target);
    callback(h.flow.expressionInfoForTesting(this));
    return new ExpressionTypeAnalysisResult(type: type);
  }
}

class _GetSsaNodes extends Expression {
  final void Function(SsaNodeHarness) callback;

  _GetSsaNodes(this.callback, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    callback(SsaNodeHarness(h.flow));
    h.irBuilder.atom('null', Kind.expression, location: location);
    return ExpressionTypeAnalysisResult(
      type: SharedTypeView(h.typeAnalyzer.nullType),
    );
  }
}

class _WhyNotPromoted extends Expression {
  final Expression target;

  final void Function(Map<SharedTypeView, NonPromotionReason>) callback;

  _WhyNotPromoted(this.target, this.callback, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    target.preVisit(visitor);
  }

  @override
  String toString() => '$target (whyNotPromoted)';

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var type = h.typeAnalyzer.analyzeExpression(
      target,
      h.operations.unknownType,
    );
    h.flow.forwardExpression(this, target);
    callback(h.flow.whyNotPromoted(this)());
    return new ExpressionTypeAnalysisResult(type: type);
  }
}

class _WhyNotPromoted_ImplicitThis extends Expression {
  final Type staticType;

  final void Function(Map<SharedTypeView, NonPromotionReason>) callback;

  _WhyNotPromoted_ImplicitThis(
    this.staticType,
    this.callback, {
    required super.location,
  });

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => 'implicit this (whyNotPromoted)';

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    callback(h.flow.whyNotPromotedImplicitThis(SharedTypeView(staticType))());
    h.irBuilder.atom('noop', Kind.expression, location: location);
    return ExpressionTypeAnalysisResult(
      type: SharedTypeView(h.typeAnalyzer.nullType),
    );
  }
}

extension ExpressionExtensionForFlowAnalysisTesting on ProtoExpression {
  /// Creates an [Expression] that, when analyzed, will behave the same as
  /// `this`, but after visiting it, will cause [callback] to be passed the
  /// [ExpressionInfo] associated with it.  If the expression has no flow
  /// analysis information associated with it, `null` will be passed to
  /// [callback].
  Expression getExpressionInfo(
    void Function(ExpressionInfo<SharedTypeView>?) callback,
  ) {
    var location = computeLocation();
    return new _GetExpressionInfo(
      asExpression(location: location),
      callback,
      location: location,
    );
  }

  /// Creates an [Expression] that, when analyzed, will behave the same as
  /// `this`, but after visiting it, will cause [callback] to be passed the
  /// non-promotion info associated with it.  If the expression has no
  /// non-promotion info, an empty map will be passed to [callback].
  Expression whyNotPromoted(
    void Function(Map<SharedTypeView, NonPromotionReason>) callback,
  ) {
    var location = computeLocation();
    return new _WhyNotPromoted(
      asExpression(location: location),
      callback,
      location: location,
    );
  }
}
