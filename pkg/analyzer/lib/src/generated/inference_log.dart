// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/shared_inference_log.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';

final bool _assertionsEnabled = () {
  bool enabled = false;
  assert(enabled = true);
  return enabled;
}();

/// Expando used by [_InferenceLogWriterImpl.setExpressionVisitCodePath] to
/// record the code path that's being used by the [ResolverVisitor] to visit a
/// subexpression.
final _expressionVisitCodePaths = Expando<ExpressionVisitCodePath>();

/// The [InferenceLogWriter] currently being used by the analyzer, if inference
/// logging is active, otherwise `null`.
InferenceLogWriter? _inferenceLogWriter;

/// Expando storing a value `true` for each expression that has been passed to
/// [_InferenceLogWriterImpl.enterExpression].
///
/// This is used by [_InferenceLogWriterImpl.assertExpressionWasRecorded] to
/// verify that [_InferenceLogWriterImpl.enterExpression] was called when it
/// should be.
final _recordedExpressions = Expando<bool>();

/// Returns the [InferenceLogWriter] currently being used by the analyzer, if
/// inference logging is active, otherwise `null`.
InferenceLogWriter? get inferenceLogWriter => _inferenceLogWriter;

/// Starts up inference logging if appropriate.
///
/// Inference logging will be started up if either of the following conditions
/// are met:
/// - The [dump] parameter is `true` (in which case the log will immediately
///   start dumping events to standard output)
/// - Assertions are enabled.
void conditionallyStartInferenceLogging({bool dump = false}) {
  assert(_inferenceLogWriter == null);
  if (_assertionsEnabled || dump) {
    var inferenceLogWriter = _inferenceLogWriter = _InferenceLogWriterImpl();
    if (dump) {
      inferenceLogWriter.dump();
    }
  }
}

/// Stops inference logging if it's been started.
void stopInferenceLogging() {
  _inferenceLogWriter = null;
}

/// Enum of all the possible code paths that can be used by the
/// [ResolverVisitor] to visit expressions when inside the body or initializer
/// of a top level construct.
enum ExpressionVisitCodePath {
  /// The expression is being visited via [ResolverVisitor.analyzeExpression].
  analyzeExpression,

  /// The expression is the identifier in a "for each" loop, so it is not a true
  /// expression, and it is being visited directly using [Expression.accept].
  forEachIdentifier,
}

/// The [SharedInferenceLogWriter] interface, augmented with analyzer-specific
/// functionality.
abstract interface class InferenceLogWriter
    implements SharedInferenceLogWriter {
  /// Checks that [enterExpression] was properly called for [expression].
  ///
  /// This is called from [ResolverVisitor.dispatchExpression], to verify that
  /// each expression's visit method property calls [enterExpression].
  void assertExpressionWasRecorded(Expression expression);

  /// Called when type inference enters the body of a top level function or
  /// method, or the initializer of a top level variable or field, or the
  /// initializers and body of a constructor.
  void enterBodyOrInitializer(AstNode node);

  /// Called when type inference enters the body of a top level function or
  /// method, or the initializer of a top level variable or field, or the
  /// initializers and body of a constructor.
  void exitBodyOrInitializer();

  /// Records [source] as the code path that the [ResolverVisitor] is about to
  /// use to visit the expression [node].
  ///
  /// An assertion in [enterExpression] verifies that when inside a method body
  /// or initializer (see [enterBodyOrInitializer]), every call to
  /// [enterExpression] is preceded by exactly one call to
  /// [setExpressionVisitCodePath]. This ensures that the resolution process
  /// doesn't ever try to resolve a subexpression more than once. It also
  /// ensures that every code path that resolves subexpressions inside method
  /// bodies and initializers calls this method, making it easy to statically
  /// locate these code paths.
  void setExpressionVisitCodePath(
    Expression node,
    ExpressionVisitCodePath source,
  );
}

/// The [SharedInferenceLogWriterImpl] implementation, augmented with
/// analyzer-specific functionality.
final class _InferenceLogWriterImpl extends SharedInferenceLogWriterImpl
    implements InferenceLogWriter {
  /// Whether type inference is currently inside the body of a top level
  /// function or method, or the initializer of a top level variable or field,
  /// or the initializers and body of a constructor.
  ///
  /// When this value is `true`, flow analysis is active, and expressions must
  /// be visited using [ResolverVisitor.analyzeExpression].
  bool _inBodyOrInitializer = false;

  @override
  void assertExpressionWasRecorded(Object expression) {
    if (_recordedExpressions[expression] ?? false) return;
    fail('failed to record ${describe(expression)}');
  }

  @override
  void enterAnnotation(covariant Annotation node) {
    // ResolverVisitor.visitAnnotation is sometimes called from
    // AstResolver.resolveAnnotation during summary linking. When this happens,
    // the state will be a "top" state even though _traceableParent suggests
    // that we should be in some other state. So to avoid a bogus exception, if
    // the state is a "top" state, don't bother calling `checkCall`.
    if (state.kind != StateKind.top) {
      checkCall(
        method: 'enterAnnotation',
        arguments: [node],
        expectedNode: traceableAncestor(node),
      );
    }
    super.enterAnnotation(node);
  }

  @override
  void enterBodyOrInitializer(AstNode node) {
    assert(!_inBodyOrInitializer, 'Already in a body or initializer');
    _inBodyOrInitializer = true;
  }

  @override
  void enterElement(covariant CollectionElement node) {
    checkCall(
      method: 'enterElement',
      arguments: [node],
      expectedNode: traceableAncestor(node),
    );
    super.enterElement(node);
  }

  @override
  void enterExpression(covariant Expression node, TypeImpl contextType) {
    assert(
      !_inBodyOrInitializer || _expressionVisitCodePaths[node] != null,
      'When in a body or initializer, setExpressionVisitSource should be '
      'called prior to enterExpression. Not called for $node.',
    );
    checkCall(
      method: 'enterExpression',
      arguments: [node, contextType],
      expectedNode: traceableAncestor(node),
    );
    super.enterExpression(node, contextType);
    _recordedExpressions[node] = true;
  }

  @override
  void enterExtensionOverride(
    covariant ExtensionOverride node,
    TypeImpl contextType,
  ) {
    checkCall(
      method: 'enterExtensionOverride',
      arguments: [node, contextType],
      expectedNode: traceableAncestor(node),
    );
    super.enterExtensionOverride(node, contextType);
    _recordedExpressions[node] = true;
  }

  @override
  void enterLValue(covariant Expression node) {
    checkCall(
      method: 'enterLValue',
      arguments: [node],
      expectedNode: traceableAncestor(node),
    );
    super.enterLValue(node);
  }

  @override
  void enterPattern(covariant DartPattern node) {
    checkCall(
      method: 'enterPattern',
      arguments: [node],
      expectedNode: traceableAncestor(node),
    );
    super.enterPattern(node);
  }

  @override
  void enterStatement(covariant Statement node) {
    checkCall(
      method: 'enterStatement',
      arguments: [node],
      expectedNode: traceableAncestor(node),
    );
    super.enterStatement(node);
  }

  @override
  void exitBodyOrInitializer() {
    assert(_inBodyOrInitializer, 'Not in a method body or initializer');
    _inBodyOrInitializer = false;
  }

  @override
  void recordExpressionRewrite({
    Object? oldExpression,
    required Object newExpression,
  }) {
    if (oldExpression != null) {
      assertExpressionWasRecorded(oldExpression);
    }
    _recordedExpressions[newExpression] = true;
    super.recordExpressionRewrite(
      oldExpression: oldExpression,
      newExpression: newExpression,
    );
  }

  @override
  void recordNullShortedType(Object expression, SharedType type) {
    assertExpressionWasRecorded(expression);
    super.recordNullShortedType(expression, type);
  }

  @override
  void setExpressionVisitCodePath(
    Expression node,
    ExpressionVisitCodePath source,
  ) {
    assert(
      _expressionVisitCodePaths[node] == null,
      'An expression visit source was already set for $node',
    );
    _expressionVisitCodePaths[node] = source;
  }

  /// Returns the nearest ancestor of [node] for which a call to `enter...`
  /// should have been made.
  ///
  /// This is used to verify proper nesting of `enter...` method calls.
  AstNode? traceableAncestor(covariant AstNode node) {
    for (var parent = node.parent; ; parent = parent.parent) {
      switch (parent) {
        case null:
        case Annotation():
        case CollectionElement():
        case DartPattern():
        case Statement():
          return parent;
        default:
          break;
      }
    }
  }
}
