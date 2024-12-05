// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/shared_inference_log.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';

final bool _assertionsEnabled = () {
  bool enabled = false;
  assert(enabled = true);
  return enabled;
}();

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

/// The [SharedInferenceLogWriter] interface, augmented with analyzer-specific
/// functionality.
abstract interface class InferenceLogWriter
    implements
        SharedInferenceLogWriter<DartType, DartType, TypeParameterElement> {
  /// Checks that [enterExpression] was properly called for [expression].
  ///
  /// This is called from [ResolverVisitor.dispatchExpression], to verify that
  /// each expression's visit method property calls [enterExpression].
  void assertExpressionWasRecorded(Expression expression);
}

/// The [SharedInferenceLogWriterImpl] implementation, augmented with
/// analyzer-specific functionality.
final class _InferenceLogWriterImpl extends SharedInferenceLogWriterImpl<
    DartType, DartType, TypeParameterElement> implements InferenceLogWriter {
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
          expectedNode: traceableAncestor(node));
    }
    super.enterAnnotation(node);
  }

  @override
  void enterElement(covariant CollectionElement node) {
    checkCall(
        method: 'enterElement',
        arguments: [node],
        expectedNode: traceableAncestor(node));
    super.enterElement(node);
  }

  @override
  void enterExpression(covariant Expression node, DartType contextType) {
    checkCall(
        method: 'enterExpression',
        arguments: [node, contextType],
        expectedNode: traceableAncestor(node));
    super.enterExpression(node, contextType);
    _recordedExpressions[node] = true;
  }

  @override
  void enterExtensionOverride(
      covariant ExtensionOverride node, DartType contextType) {
    checkCall(
        method: 'enterExtensionOverride',
        arguments: [node, contextType],
        expectedNode: traceableAncestor(node));
    super.enterExtensionOverride(node, contextType);
    _recordedExpressions[node] = true;
  }

  @override
  void enterLValue(covariant Expression node) {
    checkCall(
        method: 'enterLValue',
        arguments: [node],
        expectedNode: traceableAncestor(node));
    super.enterLValue(node);
  }

  @override
  void enterPattern(covariant DartPattern node) {
    checkCall(
        method: 'enterPattern',
        arguments: [node],
        expectedNode: traceableAncestor(node));
    super.enterPattern(node);
  }

  @override
  void enterStatement(covariant Statement node) {
    checkCall(
        method: 'enterStatement',
        arguments: [node],
        expectedNode: traceableAncestor(node));
    super.enterStatement(node);
  }

  /// Returns the nearest ancestor of [node] for which a call to `enter...`
  /// should have been made.
  ///
  /// This is used to verify proper nesting of `enter...` method calls.
  AstNode? traceableAncestor(covariant AstNode node) {
    for (var parent = node.parent;; parent = parent.parent) {
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
