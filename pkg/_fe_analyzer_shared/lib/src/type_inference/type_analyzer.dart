// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../flow_analysis/flow_analysis.dart';
import 'type_analysis_result.dart';
import 'type_operations.dart';

/// Type analysis logic to be shared between the analyzer and front end.  The
/// intention is that the client's main type inference visitor class can include
/// this mix-in and call shared analysis logic as needed.
///
/// Concrete methods in this mixin, typically named `analyzeX` for some `X`,
/// are intended to be called by the client in order to analyze an AST node (or
/// equivalent) of type `X`; a client's `visit` method shouldn't have to do much
/// than call the corresponding `analyze` method, passing in AST node's children
/// and other properties, possibly take some client-specific actions with the
/// returned value (such as storing intermediate inference results), and then
/// return the returned value up the call stack.
///
/// Abstract methods in this mixin are intended to be implemented by the client;
/// these are called by the `analyzeX` methods to report analysis results, to
/// query the client-specific information (e.g. to obtain the client's
/// representation of core types), and to trigger recursive analysis of child
/// AST nodes.
mixin TypeAnalyzer<Node extends Object, Statement extends Node,
    Expression extends Node, Variable extends Object, Type extends Object> {
  /// Returns the type `double`.
  Type get doubleType;

  /// Returns the type `dynamic`.
  Type get dynamicType;

  /// Returns the client's [FlowAnalysis] object.
  ///
  /// May be `null`, because the analyzer doesn't have a flow analysis object
  /// in play when analyzing top level initializers (see
  /// https://github.com/dart-lang/sdk/issues/49701).
  FlowAnalysis<Node, Statement, Expression, Variable, Type>? get flow;

  /// Returns the type `int`.
  Type get intType;

  /// Returns the client's implementation of the [TypeOperations] class.
  TypeOperations<Type> get typeOperations;

  /// Returns the unknown type context (`?`) used in type inference.
  Type get unknownType;

  /// Analyzes an integer literal, given the type context [context].
  IntTypeAnalysisResult<Type> analyzeIntLiteral(Type context) {
    bool convertToDouble = !typeOperations.isSubtypeOf(intType, context) &&
        typeOperations.isSubtypeOf(doubleType, context);
    Type type = convertToDouble ? doubleType : intType;
    return new IntTypeAnalysisResult<Type>(
        type: type, convertedToDouble: convertToDouble);
  }

  /// Calls the appropriate `analyze` method according to the form of
  /// [expression].
  ///
  /// For example, if [node] is a binary expression (`a + b`), calls
  /// [analyzeBinaryExpression].
  ExpressionTypeAnalysisResult<Type> dispatchExpression(
      Expression expression, Type context);

  /// Calls the appropriate `analyze` method according to the form of
  /// [statement].
  ///
  /// For example, if [statement] is a `while` loop, calls [analyzeWhileLoop].
  void dispatchStatement(Statement statement);
}
