// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' show DartType;

/// Callback interface used by [TypeInferrer] to report the results of type
/// inference to a client.
///
/// The interface is structured as a set of enter/exit methods.  The enter
/// methods are called as the inferrer recurses down through the AST, and the
/// exit methods are called on the way back up.  The enter methods take a
/// [DartType] argument representing the downwards inference context, and return
/// a bool indicating whether the TypeInferenceListener needs to know the final
/// inferred type; the exit methods take [DartType] argument representing the
/// final inferred type.
///
/// The default implementation (in this base class) does nothing, however it can
/// be used to debug type inference by uncommenting the `print` calls in
/// [debugExpressionEnter] and [debugExpressionExit].
class TypeInferenceListener {
  bool asExpressionEnter(DartType typeContext) =>
      debugExpressionEnter("asExpression", typeContext);

  void asExpressionExit(DartType inferredType) =>
      debugExpressionExit("asExpression", inferredType);

  bool boolLiteralEnter(DartType typeContext) =>
      debugExpressionEnter("boolLiteral", typeContext);

  void boolLiteralExit(DartType inferredType) =>
      debugExpressionExit("boolLiteral", inferredType);

  bool conditionalExpressionEnter(DartType typeContext) =>
      debugExpressionEnter("conditionalExpression", typeContext);

  void conditionalExpressionExit(DartType inferredType) =>
      debugExpressionExit("conditionalExpression", inferredType);

  bool constructorInvocationEnter(DartType typeContext) =>
      debugExpressionEnter("constructorInvocation", typeContext);

  void constructorInvocationExit(DartType inferredType) =>
      debugExpressionExit("constructorInvocation", inferredType);

  bool debugExpressionEnter(String expressionType, DartType typeContext) {
    // print('Enter $expressionType (context=$typeContext)'); return true;
    return false;
  }

  debugExpressionExit(String expressionType, DartType inferredType) {
    // print('Exit $expressionType (type=$inferredType)');
  }

  bool doubleLiteralEnter(DartType typeContext) =>
      debugExpressionEnter("doubleLiteral", typeContext);

  void doubleLiteralExit(DartType inferredType) =>
      debugExpressionExit("doubleLiteral", inferredType);

  bool functionExpressionEnter(DartType typeContext) =>
      debugExpressionEnter("functionExpression", typeContext);

  void functionExpressionExit(DartType inferredType) =>
      debugExpressionExit("functionExpression", inferredType);

  bool intLiteralEnter(DartType typeContext) =>
      debugExpressionEnter("intLiteral", typeContext);

  void intLiteralExit(DartType inferredType) =>
      debugExpressionExit("intLiteral", inferredType);

  bool isExpressionEnter(DartType typeContext) =>
      debugExpressionEnter("isExpression", typeContext);

  void isExpressionExit(DartType inferredType) =>
      debugExpressionExit("isExpression", inferredType);

  bool listLiteralEnter(DartType typeContext) =>
      debugExpressionEnter("listLiteral", typeContext);

  void listLiteralExit(DartType inferredType) =>
      debugExpressionExit("listLiteral", inferredType);

  bool methodInvocationEnter(DartType typeContext) =>
      debugExpressionEnter("methodInvocation", typeContext);

  void methodInvocationExit(DartType inferredType) =>
      debugExpressionExit("methodInvocation", inferredType);

  bool nullLiteralEnter(DartType typeContext) =>
      debugExpressionEnter("nullLiteral", typeContext);

  void nullLiteralExit(DartType inferredType) =>
      debugExpressionExit("nullLiteral", inferredType);

  bool staticGetEnter(DartType typeContext) =>
      debugExpressionEnter("staticGet", typeContext);

  void staticGetExit(DartType inferredType) =>
      debugExpressionExit("staticGet", inferredType);

  bool stringConcatenationEnter(DartType typeContext) =>
      debugExpressionEnter("stringConcatenation", typeContext);

  void stringConcatenationExit(DartType inferredType) =>
      debugExpressionExit("stringConcatenation", inferredType);

  bool stringLiteralEnter(DartType typeContext) =>
      debugExpressionEnter("StringLiteral", typeContext);

  void stringLiteralExit(DartType inferredType) =>
      debugExpressionExit("StringLiteral", inferredType);

  bool variableGetEnter(DartType typeContext) =>
      debugExpressionEnter("variableGet", typeContext);

  void variableGetExit(DartType inferredType) =>
      debugExpressionExit("variableGet", inferredType);

  bool variableSetEnter(DartType typeContext) =>
      debugExpressionEnter("variableSet", typeContext);

  void variableSetExit(DartType inferredType) =>
      debugExpressionExit("variableSet", inferredType);
}
