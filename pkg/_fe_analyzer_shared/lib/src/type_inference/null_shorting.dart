// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'type_analyzer.dart';
/// @docImport 'type_analyzer_operations.dart';
library;

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';

import '../flow_analysis/flow_analysis.dart';
import '../flow_analysis/flow_analysis_operations.dart';
import 'type_analysis_result.dart';

/// Null shorting logic to be shared between the analyzer and the CFE.
///
/// This mixin should be used by the same class that mixes in [TypeAnalyzer].
///
/// The type parameter [Guard] should be instantiated with the data structure
/// used by the client to desugar null-aware accesses. (The analyzer can
/// instantiate this with `Null`, since it doesn't do desugaring.)
mixin NullShortingMixin<
  Guard,
  Expression extends Object,
  Variable extends Object
>
    on TypeAnalysisNullShortingInterface<Expression, Variable> {
  /// Stack of [Guard] objects associated with null-shorting operations that
  /// haven't been terminated yet.
  final _guards = <Guard>[];

  @override
  int get nullShortingDepth => _guards.length;

  @override
  ExpressionTypeAnalysisResult finishNullShorting(
    int targetDepth,
    ExpressionTypeAnalysisResult innerResult, {
    required Expression wholeExpression,
  }) {
    assert(targetDepth < nullShortingDepth);
    SharedTypeView inferredType = operations.makeNullable(innerResult.type);
    do {
      // End non-nullable promotion of the null-aware variable.
      flow.nullAwareAccess_end();
      // If any expression info or expression reference was stored for the
      // null-aware expression, it was only valid in the case where the target
      // expression was not null. So it needs to be cleared now.
      flow.storeExpressionInfo(wholeExpression, null);
      innerResult = handleNullShortingStep(
        innerResult,
        _guards.removeLast(),
        inferredType,
      );
      assert(identical(innerResult.type, inferredType));
    } while (nullShortingDepth > targetDepth);
    handleNullShortingFinished(inferredType);
    return innerResult;
  }

  /// Hook called by [finishNullShorting] after terminating all the null
  /// shorting that needs to be terminated for a given expression.
  ///
  /// [inferredType] is the (nullable) type of the final expression.
  void handleNullShortingFinished(SharedTypeView inferredType) {}

  /// Hook called by [finishNullShorting] after terminating a single
  /// null-shorting operation.
  ///
  /// [innerResult] is the result of analyzing the expression, before
  /// termination of null shorting.
  ///
  /// [guard] is the value that was passed to [startNullShorting] when the
  /// null-shorting operation was started.
  ///
  /// [inferredType] is the (nullable) type of the final expression.
  ///
  /// The return value is an [ExpressionTypeAnalysisResult] representing the
  /// result of analyzing the expression, after termination of null shorting.
  ExpressionTypeAnalysisResult handleNullShortingStep(
    ExpressionTypeAnalysisResult innerResult,
    Guard guard,
    SharedTypeView inferredType,
  ) => new ExpressionTypeAnalysisResult(type: inferredType);

  /// Starts null shorting for a null-aware expression that participates in
  /// null-shorting.
  ///
  /// [targetInfo] should be the flow analysis expression info for the target of
  /// the null-aware operation (the expression to the left of the `?.`), and
  /// [targetType] should be its static type.
  ///
  /// The flow analysis expression info for the target (assuming it is not null)
  /// is returned.
  ///
  /// [guard] should be the data structure that will be used by the client to
  /// desugar the null-aware access. It will be passed to
  /// [handleNullShortingStep] when the null shorting for this particular
  /// null-aware expression is terminated.
  ///
  /// If the client desugars the null-aware access using a guard variable (e.g.,
  /// if it desugars `a?.b` into `let x = a in x == null ? null : x.b`), it
  /// should pass in the variable used for desugaring as [guardVariable]. Flow
  /// analysis will ensure that this variable is promoted to the appropriate
  /// type in the "not null" code path.
  ExpressionInfo? startNullShorting(
    Guard guard,
    ExpressionInfo? targetInfo,
    SharedTypeView targetType, {
    Variable? guardVariable,
  }) {
    // Ensure the initializer of [_nullAwareVariable] is promoted to
    // non-nullable.
    targetInfo = flow.nullAwareAccess_rightBegin(
      targetInfo,
      targetType,
      guardVariable: guardVariable,
    );
    _guards.add(guard);
    return targetInfo;
  }
}

abstract interface class TypeAnalysisNullShortingInterface<
  Expression extends Object,
  Variable extends Object
> {
  /// Returns the client's [FlowAnalysis] object.
  FlowAnalysisNullShortingInterface<Expression, Variable> get flow;

  /// Returns the number of null-shorting operations that haven't been
  /// terminated yet.
  int get nullShortingDepth;

  /// The [FlowAnalysisTypeOperations], used to access types and check
  /// subtyping.
  ///
  /// Typically this will be an instance of [TypeAnalyzerOperations].
  FlowAnalysisTypeOperations get operations;

  /// Terminates one or more null-shorting operations that were previously
  /// started using [NullShortingMixin.startNullShorting].
  ///
  /// This method should be called at the point where the null-shorting flow
  /// control path rejoins with the main flow control path. For example, when
  /// analyzing the expression `i?.toString()`, this method should be called
  /// after analyzing the call to `toString()`.
  ///
  /// [targetDepth] should be a value previously returned by
  /// [nullShortingDepth]. Null-shorting operations will be terminated until the
  /// null-shorting depth returns to this value. Caller is required to pass in
  /// a value that is strictly less than [nullShortingDepth] (that is, there
  /// must be at least one null-shorting operation that needs to be terminated).
  ///
  /// [innerResult] should be the analysis results from the expression that was
  /// just analyzed, prior to termination of null shorting. For example, if the
  /// expression that is being analyzed is `i?.toString()`, [innerResult]
  /// should represent `i.toString()`.
  ///
  /// The return value is an [ExpressionTypeAnalysisResult] representing the
  /// result of analyzing the full expression, after termination of null
  /// shorting. The value of the [ExpressionTypeAnalysisResult.type] field will
  /// account for the fact that the full expression might evaluate to `null`;
  /// for example, if the expression that is being analyzed is `i?.toString()`,
  /// that type will be `String?`.
  ExpressionTypeAnalysisResult finishNullShorting(
    int targetDepth,
    ExpressionTypeAnalysisResult innerResult, {
    required Expression wholeExpression,
  });
}
