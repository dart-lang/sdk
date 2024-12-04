// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';

/// Helper for verifying resolution of assignments, in form of explicit
/// an [AssignmentExpression], or a [PrefixExpression] or [PostfixExpression]
/// when the operator is an increment operator.
class AssignmentVerifier {
  final ErrorReporter _errorReporter;

  AssignmentVerifier(this._errorReporter);

  /// We resolved [node] and found that it references the [requested] element.
  /// Verify that this element is actually writable.
  ///
  /// If the [requested] element is `null`, we might have the [recovery]
  /// element, which is definitely not a valid write target. We want to report
  /// a good error about this.
  ///
  /// When the [receiverType] is not `null`, we report
  /// [CompileTimeErrorCode.UNDEFINED_SETTER] instead of a more generic
  /// [CompileTimeErrorCode.UNDEFINED_IDENTIFIER].
  void verify({
    required SimpleIdentifier node,
    required Element2? requested,
    required Element2? recovery,
    required DartType? receiverType,
  }) {
    if (requested != null) {
      if (requested is VariableElement2) {
        if (requested.isConst) {
          _errorReporter.atNode(
            node,
            CompileTimeErrorCode.ASSIGNMENT_TO_CONST,
          );
        }
      }
      return;
    }

    if (recovery is DynamicElementImpl2 ||
        recovery is InterfaceElement2 ||
        recovery is TypeAliasElement2 ||
        recovery is TypeParameterElement2) {
      _errorReporter.atNode(
        node,
        CompileTimeErrorCode.ASSIGNMENT_TO_TYPE,
      );
    } else if (recovery is LocalFunctionElement ||
        recovery is TopLevelFunctionElement) {
      _errorReporter.atNode(
        node,
        CompileTimeErrorCode.ASSIGNMENT_TO_FUNCTION,
      );
    } else if (recovery is MethodElement2) {
      _errorReporter.atNode(
        node,
        CompileTimeErrorCode.ASSIGNMENT_TO_METHOD,
      );
    } else if (recovery is PrefixElement2) {
      if (recovery.name3 case var prefixName?) {
        _errorReporter.atNode(
          node,
          CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
          arguments: [prefixName],
        );
      }
    } else if (recovery is GetterElement) {
      var variable = recovery.variable3;
      if (variable == null) {
        return;
      }

      var variableName = variable.name3;
      if (variableName == null) {
        return;
      }

      if (variable.isConst) {
        _errorReporter.atNode(
          node,
          CompileTimeErrorCode.ASSIGNMENT_TO_CONST,
        );
      } else if (variable is FieldElement2 && variable.isSynthetic) {
        _errorReporter.atNode(
          node,
          CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER,
          arguments: [
            variableName,
            variable.enclosingElement2.displayName,
          ],
        );
      } else {
        _errorReporter.atNode(
          node,
          CompileTimeErrorCode.ASSIGNMENT_TO_FINAL,
          arguments: [variableName],
        );
      }
    } else if (recovery is MultiplyDefinedElementImpl2) {
      // Will be reported in ErrorVerifier.
    } else {
      if (node.isSynthetic) {
        return;
      }
      if (receiverType != null) {
        _errorReporter.atNode(
          node,
          CompileTimeErrorCode.UNDEFINED_SETTER,
          arguments: [node.name, receiverType],
        );
      } else {
        _errorReporter.atNode(
          node,
          CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
          arguments: [node.name],
        );
      }
    }
  }
}
