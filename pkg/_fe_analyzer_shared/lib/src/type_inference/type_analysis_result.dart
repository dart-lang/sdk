// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'variable_bindings.dart';

/// Container for the result of running type analysis on an expression.
///
/// This class keeps track of a provisional type of the expression (prior to
/// resolving null shorting) as well as the information necessary to resolve
/// null shorting.
abstract class ExpressionTypeAnalysisResult<Type extends Object> {
  /// Type of the expression before resolving null shorting.
  ///
  /// For example, if `this` is the result of analyzing `(... as int?)?.isEven`,
  /// [provisionalType] will be `bool`, because the `isEven` getter returns
  /// `bool`, and it is not yet known (until looking at the surrounding code)
  /// whether there will be additional selectors after `isEven` that should act
  /// on the `bool` type.
  Type get provisionalType;

  /// Resolves any pending null shorting.  For example, if `this` is the result
  /// of analyzing `(... as int?)?.isEven`, then calling [resolveShorting] will
  /// cause the `?.` to be desugared (if code generation is occurring) and will
  /// return the type `bool?`.
  ///
  /// TODO(paulberry): document what calls back to the client might be made by
  /// invoking this method.
  Type resolveShorting();
}

/// Container for the result of running type analysis on an integer literal.
class IntTypeAnalysisResult<Type extends Object>
    extends SimpleTypeAnalysisResult<Type> {
  /// Whether the integer literal was converted to a double.
  final bool convertedToDouble;

  IntTypeAnalysisResult({required super.type, required this.convertedToDouble});
}

/// Data structure returned by the [TypeAnalyzer] `analyze` methods for
/// patterns.
abstract class PatternDispatchResult<Node extends Object,
    Expression extends Node, Variable extends Object, Type extends Object> {
  /// The AST node for this pattern.
  Node get node;

  /// The type schema for this pattern.
  Type get typeSchema;

  /// Called by the [TypeAnalyzer] when an attempt is made to match this
  /// pattern.
  ///
  /// [matchedType] is the type of the thing being matched (for a variable
  /// declaration, this is the type of the initializer or substructure thereof;
  /// for a switch statement this is the type of the scrutinee or substructure
  /// thereof).
  ///
  /// [bindings] is a data structure keeping track of the variable patterns seen
  /// so far and their type information.
  ///
  /// [isFinal] and [isLate] only apply to variable patterns, and indicate
  /// whether the variable in question should be late and/or final.
  ///
  /// [initializer] is only present if [node] is the principal pattern of a
  /// variable declaration; it is the variable declaration's initializer
  /// expression.  This is used by flow analysis to track when the truth or
  /// falsity of a boolean variable causes other variables to be promoted.
  ///
  /// If the match is happening in an irrefutable context, [irrefutableContext]
  /// should be the containing AST node that establishes the context as
  /// irrefutable.  Otherwise it should be `null`.
  void match(Type matchedType, VariableBindings<Node, Variable, Type> bindings,
      {required bool isFinal,
      required bool isLate,
      Expression? initializer,
      required Node? irrefutableContext});
}

/// Container for the result of running type analysis on an expression that does
/// not contain any null shorting.
class SimpleTypeAnalysisResult<Type extends Object>
    implements ExpressionTypeAnalysisResult<Type> {
  /// The static type of the expression.
  final Type type;

  SimpleTypeAnalysisResult({required this.type});

  @override
  Type get provisionalType => type;

  @override
  Type resolveShorting() => type;
}
