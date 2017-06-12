// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/scanner.dart' show Token;
import 'package:front_end/src/fasta/type_inference/type_promotion.dart';
import 'package:kernel/ast.dart';

/// An abstract class containing factory methods that create AST objects.
///
/// Itended for use by [BodyBuilder] so that it can create either analyzer or
/// kernel ASTs depending on which concrete factory it is connected to.
///
/// This class is defined in terms of the builder's shadow AST mixins (which are
/// shared between kernel and analyzer shadow AST representations).
///
/// Note that the analyzer AST representation closely parallels Dart syntax,
/// whereas the kernel AST representation is desugared.  The factory methods in
/// this class correspond to the full language (prior to desugaring).  If
/// desugaring is needed, it will be performed by the concrete factory class.
///
/// TODO(paulberry): add missing methods.
///
/// TODO(paulberry): modify [BodyBuilder] so that it creates all kernel objects
/// using this interface.
///
/// TODO(paulberry): change the API to use tokens rather than charOffset, since
/// that's what analyzer ASTs need.  Note that analyzer needs multiple tokens
/// for many AST constructs, not just one.  Note also that for kernel codegen
/// we want to be very careful not to keep tokens around too long, so consider
/// having a `toLocation` method on AstFactory that changes tokens to an
/// abstract type (`int` for kernel, `Token` for analyzer).
///
/// TODO(paulberry): in order to interface with analyzer, we'll need to
/// shadow-ify [DartType], since analyzer ASTs need to be able to record the
/// exact tokens that were used to specify a type.
abstract class AstFactory<V> {
  /// Creates an [Arguments] data structure.
  Arguments arguments(List<Expression> positional,
      {List<DartType> types, List<NamedExpression> named});

  /// Creates an `as` expression.
  AsExpression asExpression(Expression operand, Token operator, DartType type);

  /// Creates an `await` expression.
  AwaitExpression awaitExpression(Token keyword, Expression operand);

  /// Creates a statement block.
  Block block(List<Statement> statements, Token beginToken);

  /// Creates a boolean literal.
  BoolLiteral boolLiteral(bool value, Token token);

  /// Creates a conditional expression.
  ConditionalExpression conditionalExpression(Expression condition,
      Expression thenExpression, Expression elseExpression);

  /// Creates a constructor invocation.
  ConstructorInvocation constructorInvocation(
      Constructor target, Arguments arguments,
      {bool isConst: false});

  /// Creates a direct method invocation.
  DirectMethodInvocation directMethodInvocation(
      Expression receiver, Procedure target, Arguments arguments);

  /// Creates a direct property get.
  DirectPropertyGet directPropertyGet(Expression receiver, Member target);

  /// Creates a direct property get.
  DirectPropertySet directPropertySet(
      Expression receiver, Member target, Expression value);

  /// Creates a double literal.
  DoubleLiteral doubleLiteral(double value, Token token);

  /// Creates an expression statement.
  ExpressionStatement expressionStatement(Expression expression);

  /// Creates a function expression.
  FunctionExpression functionExpression(FunctionNode function, Token token);

  /// Creates an `if` statement.
  Statement ifStatement(
      Expression condition, Statement thenPart, Statement elsePart);

  /// Creates an integer literal.
  IntLiteral intLiteral(int value, Token token);

  /// Creates an `is` expression.
  Expression isExpression(
      Expression expression, DartType type, Token token, bool isInverted);

  /// Creates a list literal expression.
  ///
  /// If the list literal did not have an explicitly declared type argument,
  /// [typeArgument] should be `null`.
  ListLiteral listLiteral(List<Expression> expressions, DartType typeArgument,
      bool isConst, Token token);

  /// Creates a logical expression in for of `x && y` or `x || y`.
  LogicalExpression logicalExpression(
      Expression left, String operator, Expression right);

  /// Creates a map literal expression.
  ///
  /// If the map literal did not have an explicitly declared type argument,
  /// [keyType] and [valueType] should be `null`.
  MapLiteral mapLiteral(
      Token beginToken, Token constKeyword, List<MapEntry> entries,
      {DartType keyType: const DynamicType(),
      DartType valueType: const DynamicType()});

  /// Creates a method invocation of form `x.foo(y)`.
  MethodInvocation methodInvocation(
      Expression receiver, Name name, Arguments arguments,
      [Procedure interfaceTarget]);

  /// Create an expression of form `!x`.
  Not not(Token token, Expression operand);

  /// Creates a null literal expression.
  NullLiteral nullLiteral(Token token);

  /// Creates a read of a property.
  PropertyGet propertyGet(Expression receiver, Name name,
      [Member interfaceTarget]);

  /// Creates a write of a property.
  PropertySet propertySet(Expression receiver, Name name, Expression value,
      [Member interfaceTarget]);

  /// Create a `rethrow` expression.
  Rethrow rethrowExpression(Token keyword);

  /// Creates a return statement.
  Statement returnStatement(Expression expression, Token token);

  /// Updates an [Arguments] data structure with the given generic [types].
  /// Should only be used when [types] were specified explicitly.
  void setExplicitArgumentTypes(Arguments arguments, List<DartType> types);

  /// Creates a read of a static variable.
  StaticGet staticGet(Member readTarget, Token token);

  /// Creates a static invocation.
  StaticInvocation staticInvocation(Procedure target, Arguments arguments,
      {bool isConst: false});

  /// Creates a string concatenation.
  StringConcatenation stringConcatenation(
      List<Expression> expressions, Token token);

  /// Creates a string literal.
  StringLiteral stringLiteral(String value, Token token);

  /// Creates a super method invocation.
  SuperMethodInvocation superMethodInvocation(
      Token beginToken, Name name, Arguments arguments,
      [Procedure interfaceTarget]);

  /// Create an expression of form `super.field`.
  SuperPropertyGet superPropertyGet(Name name, [Member interfaceTarget]);

  /// Create an expression of form `#foo.bar`.
  SymbolLiteral symbolLiteral(Token hashToken, String value);

  /// Create an expression of form `this`.
  ThisExpression thisExpression(Token keyword);

  /// Create a `throw` expression.
  Throw throwExpression(Token keyword, Expression expression);

  /// Create a type literal expression.
  TypeLiteral typeLiteral(DartType type);

  /// Creates a variable declaration statement declaring one variable.
  ///
  /// TODO(paulberry): analyzer makes a distinction between a single variable
  /// declaration and a variable declaration statement (which can contain
  /// multiple variable declarations).  Currently this API only makes sense for
  /// kernel, which desugars each variable declaration to its own statement.
  ///
  /// If the variable declaration did not have an explicitly declared type,
  /// [type] should be `null`.
  VariableDeclaration variableDeclaration(
      String name, Token token, int functionNestingLevel,
      {DartType type,
      Expression initializer,
      Token equalsToken,
      bool isFinal: false,
      bool isConst: false,
      bool isLocalFunction: false});

  /// Creates a read of a local variable.
  VariableGet variableGet(VariableDeclaration variable,
      TypePromotionFact<V> fact, TypePromotionScope scope, Token token);

  /// Creates a write of a local variable.
  VariableSet variableSet(VariableDeclaration variable, Expression value);
}
