// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file declares mixins which can be used to create a shadow hierarchy
/// of either the kernel or the analyzer AST representations.
///
/// These classes are intended to be used by [BodyBuilder] as a form of
/// indirection so that it can manipulate either kernel or analyzer ASTs.
///
/// All methods, getters, and setters defined in this file start with the prefix
/// "shadow" in order to avoid naming conflicts with code in kernel or analyzer.
///
/// Note that the analyzer AST representation closely parallels Dart syntax,
/// whereas the kernel AST representation is desugared.  The classes in the
/// shadow hierarchy represent the full language (prior to desugaring).
import 'package:kernel/ast.dart' show DartType;

/// Shadow mixin representing a statement block.
abstract class ShadowBlock implements ShadowStatement {
  /// Iterates through the statements contained in the block.
  Iterable<ShadowStatement> get shadowStatements;
}

/// Common interface for shadow mixins representing expressions.
///
/// TODO(paulberry): add an abstract `shadowInfer` method here to do type
/// inference.
abstract class ShadowExpression {}

/// Shadow mixin representing a function expression.
abstract class ShadowFunctionExpression implements ShadowExpression {
  /// Gets the body of the function expression.
  ShadowStatement get shadowBody;

  /// Creates a [DartType] representing the type of the function expression.
  ///
  /// If type inference has already been performed, returns the inferred type.
  /// Otherwise returns the declared type.
  DartType get shadowFunctionType;

  /// Indicates whether the function is asynchronous (`async` or `async*`)
  bool get shadowIsAsync;

  /// Indicates whether the function was declared using `=>` syntax.
  bool get shadowIsExpressionFunction;

  /// Indicates whether the function is a generator (`sync*` or `async*`)
  bool get shadowIsGenerator;

  /// Sets the return type of the function expression.
  ///
  /// Intended for use by type inference.
  void set shadowReturnType(DartType type);
}

/// Shadow mixin representing an integer literal.
abstract class ShadowIntLiteral implements ShadowExpression {}

/// Shadow mixin representing a list literal.
abstract class ShadowListLiteral implements ShadowExpression {
  /// Iterates through the expressions contained in the list literal.
  Iterable<ShadowExpression> get shadowExpressions;

  /// Gets the type argument of the list literal.  If type inference has not
  /// been performed and no explicit type argument was specified, returns
  /// `null`.
  DartType get shadowTypeArgument;

  /// Sets the type argument of the list literal.
  ///
  /// Intended for use by type inference.
  void set shadowTypeArgument(DartType type);
}

/// Shadow mixin representing a null literal.
abstract class ShadowNullLiteral implements ShadowExpression {}

/// Shadow mixin representing a return statement.
abstract class ShadowReturnStatement implements ShadowStatement {
  /// Gets the expression being returned, or `null` if this is a bare "return"
  /// statement.
  ShadowExpression get shadowExpression;
}

/// Common interface for shadow mixins representing statements.
///
/// TODO(paulberry): add an abstract `shadowInfer` method here to do type
/// inference.
abstract class ShadowStatement {}

/// Shadow mixin representing a declaration of a single variable.
abstract class ShadowVariableDeclaration implements ShadowStatement {
  /// Gets the initializer expression for the variable, or `null` if the
  /// variable has no initializer.
  ShadowExpression get shadowInitializer;

  /// Gets the type of the variable.  If type inference has not been performed
  /// and no explicit type was specified, returns `null`.
  DartType get shadowType;

  /// Sets the type of the variable.
  ///
  /// Intended for use by type inference.
  void set shadowType(DartType type);
}

/// Shadow mixin representing a "read" reference to a variable.
abstract class ShadowVariableGet implements ShadowExpression {
  /// Gets the variable declaration which is being referenced.
  ShadowVariableDeclaration get shadowDeclaration;
}
