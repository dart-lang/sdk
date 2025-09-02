// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';

/// Helper for verifying resolution of assignments, in form of explicit
/// an [AssignmentExpression], or a [PrefixExpression] or [PostfixExpression]
/// when the operator is an increment operator.
class AssignmentVerifier {
  final DiagnosticReporter _diagnosticReporter;

  AssignmentVerifier(this._diagnosticReporter);

  /// We resolved [node] and found that it references the [requested] element.
  /// Verify that this element is actually writable.
  ///
  /// If the [requested] element is `null`, we might have the [recovery]
  /// element, which is definitely not a valid write target. We want to report
  /// a good error about this.
  ///
  /// When the [receiverType] is not `null`, we report
  /// [CompileTimeErrorCode.undefinedSetter] instead of a more generic
  /// [CompileTimeErrorCode.undefinedIdentifier].
  void verify({
    required SimpleIdentifier node,
    required Element? requested,
    required Element? recovery,
    required DartType? receiverType,
  }) {
    if (requested != null) {
      if (requested is VariableElement) {
        if (requested.isConst) {
          _diagnosticReporter.atNode(
            node,
            CompileTimeErrorCode.assignmentToConst,
          );
        }
      }
      return;
    }

    if (recovery is DynamicElementImpl ||
        recovery is InterfaceElement ||
        recovery is TypeAliasElement ||
        recovery is TypeParameterElement) {
      _diagnosticReporter.atNode(node, CompileTimeErrorCode.assignmentToType);
    } else if (recovery is LocalFunctionElement ||
        recovery is TopLevelFunctionElement) {
      _diagnosticReporter.atNode(
        node,
        CompileTimeErrorCode.assignmentToFunction,
      );
    } else if (recovery is MethodElement) {
      _diagnosticReporter.atNode(node, CompileTimeErrorCode.assignmentToMethod);
    } else if (recovery is PrefixElement) {
      if (recovery.name case var prefixName?) {
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.prefixIdentifierNotFollowedByDot,
          arguments: [prefixName],
        );
      }
    } else if (recovery is GetterElement) {
      var variable = recovery.variable;
      var variableName = variable.name;
      if (variableName == null) {
        return;
      }

      if (variable.isConst) {
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.assignmentToConst,
        );
      } else if (variable is FieldElement && variable.isSynthetic) {
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.assignmentToFinalNoSetter,
          arguments: [variableName, variable.enclosingElement.displayName],
        );
      } else {
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.assignmentToFinal,
          arguments: [variableName],
        );
      }
    } else if (recovery is MultiplyDefinedElementImpl) {
      // Will be reported in ErrorVerifier.
    } else {
      if (node.isSynthetic) {
        return;
      }
      if (receiverType != null) {
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.undefinedSetter,
          arguments: [node.name, receiverType],
        );
      } else {
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.undefinedIdentifier,
          arguments: [node.name],
        );
      }
    }
  }
}
