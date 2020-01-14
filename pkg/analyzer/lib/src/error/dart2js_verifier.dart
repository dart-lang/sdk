// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';

/// Instances of the class `Dart2JSVerifier` traverse an AST structure looking
/// for hints for code that will be compiled to JS, such as
/// [HintCode.IS_DOUBLE].
class Dart2JSVerifier extends RecursiveAstVisitor<void> {
  /// The name of the `double` type.
  static const String _DOUBLE_TYPE_NAME = "double";

  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  /// Create a new instance of the [Dart2JSVerifier].
  ///
  /// @param errorReporter the error reporter
  Dart2JSVerifier(this._errorReporter);

  @override
  void visitIsExpression(IsExpression node) {
    _checkForIsDoubleHints(node);
    super.visitIsExpression(node);
  }

  /// Check for instances of `x is double`, `x is int`, `x is! double` and
  /// `x is! int`.
  ///
  /// @param node the is expression to check
  /// @return `true` if and only if a hint code is generated on the passed node
  /// See [HintCode.IS_DOUBLE],
  /// [HintCode.IS_INT],
  /// [HintCode.IS_NOT_DOUBLE], and
  /// [HintCode.IS_NOT_INT].
  bool _checkForIsDoubleHints(IsExpression node) {
    DartType type = node.type.type;
    Element element = type?.element;
    if (element != null) {
      String typeNameStr = element.name;
      LibraryElement libraryElement = element.library;
      //      if (typeNameStr.equals(INT_TYPE_NAME) && libraryElement != null
      //          && libraryElement.isDartCore()) {
      //        if (node.getNotOperator() == null) {
      //          errorReporter.reportError(HintCode.IS_INT, node);
      //        } else {
      //          errorReporter.reportError(HintCode.IS_NOT_INT, node);
      //        }
      //        return true;
      //      } else
      if (typeNameStr == _DOUBLE_TYPE_NAME &&
          libraryElement != null &&
          libraryElement.isDartCore) {
        if (node.notOperator == null) {
          _errorReporter.reportErrorForNode(HintCode.IS_DOUBLE, node);
        } else {
          _errorReporter.reportErrorForNode(HintCode.IS_NOT_DOUBLE, node);
        }
        return true;
      }
    }
    return false;
  }
}
