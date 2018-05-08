// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.forest;

// TODO(ahe): Remove this import.
import 'package:kernel/ast.dart' as kernel show Arguments;
import 'package:kernel/ast.dart';

/// A tree factory.
///
/// For now, the [Location] is always a token.
abstract class Forest<Expression, Statement, Location, Arguments> {
  const Forest();

  Arguments arguments(List<Expression> positional, Location location,
      {covariant List types, covariant List named});

  Arguments argumentsEmpty(Location location);

  List argumentsNamed(Arguments arguments);

  List<Expression> argumentsPositional(Arguments arguments);

  List argumentsTypeArguments(Arguments arguments);

  void argumentsSetTypeArguments(Arguments arguments, covariant List types);

  Expression asLiteralString(Expression value);

  /// Return a representation of a boolean literal at the given [location]. The
  /// literal has the given [value].
  Expression literalBool(bool value, Location location);

  /// Return a representation of a double literal at the given [location]. The
  /// literal has the given [value].
  Expression literalDouble(double value, Location location);

  /// Return a representation of an integer literal at the given [location]. The
  /// literal has the given [value].
  Expression literalInt(int value, Location location);

  /// Return a representation of a list literal. The [constKeyword] is the
  /// location of the `const` keyword, or `null` if there is no keyword. The
  /// [isConst] is `true` if either the `const` keyword is not-`null` or if the
  /// list literal is in a const context. The [typeArgument] is the
  /// representation of the single valid type argument preceding the list
  /// literal, or `null` if there is no type argument, there is more than one
  /// type argument, or if the type argument cannot be resolved. The
  /// [typeArguments] is the representation of all of the type arguments
  /// preceding the list literal, or `null` if there are no type arguments. The
  /// [leftBracket] is the location of the `[`. The list of [expressions] is a
  /// list of the representations of the list elements. The [rightBracket] is
  /// the location of the `]`.
  Expression literalList(
      Location constKeyword,
      bool isConst,
      Object typeArgument,
      Object typeArguments,
      Location leftBracket,
      List<Expression> expressions,
      Location rightBracket);

  /// Return a representation of a map literal. The [constKeyword] is the
  /// location of the `const` keyword, or `null` if there is no keyword. The
  /// [isConst] is `true` if either the `const` keyword is not-`null` or if the
  /// map literal is in a const context. The [keyType] is the representation of
  /// the first type argument preceding the map literal, or `null` if there are
  /// not exactly two type arguments or if the first type argument cannot be
  /// resolved. The [valueType] is the representation of the second type
  /// argument preceding the map literal, or `null` if there are not exactly two
  /// type arguments or if the second type argument cannot be resolved. The
  /// [typeArguments] is the representation of all of the type arguments
  /// preceding the map literal, or `null` if there are no type arguments. The
  /// [leftBracket] is the location of the `{`. The list of [entries] is a
  /// list of the representations of the map entries. The [rightBracket] is
  /// the location of the `}`.
  Expression literalMap(
      Location constKeyword,
      bool isConst,
      covariant keyType,
      covariant valueType,
      Object typeArguments,
      Location leftBracket,
      covariant List entries,
      Location rightBracket);

  /// Return a representation of a null literal at the given [location].
  Expression literalNull(Location location);

  /// Return a representation of a simple string literal at the given
  /// [location]. The literal has the given [value]. This does not include
  /// either adjacent strings or interpolated strings.
  Expression literalString(String value, Location location);

  Expression literalSymbol(String value, Location location);

  Expression literalType(covariant type, Location location);

  /// Return a representation of a key/value pair in a literal map. The [key] is
  /// the representation of the expression used to compute the key. The [colon]
  /// is the location of the colon separating the key and the value. The [value]
  /// is the representation of the expression used to compute the value.
  Object mapEntry(Expression key, Location colon, Expression value);

  /// Return a list that can hold [length] representations of map entries, as
  /// returned from [mapEntry].
  List mapEntryList(int length);

  int readOffset(covariant node);

  /// Given a representation of a list of [typeArguments], return the number of
  /// type arguments in the list.
  int getTypeCount(Object typeArguments);

  /// Given a representation of a list of [typeArguments], return the type
  /// associated with the argument at the given [index].
  DartType getTypeAt(Object typeArguments, int index);

  Expression loadLibrary(covariant dependency);

  Expression checkLibraryIsLoaded(covariant dependency);

  Expression asExpression(
      Expression expression, covariant type, Location location);

  Expression awaitExpression(Expression operand, Location location);

  /// Return a representation of a conditional expression. The [condition] is
  /// the condition. The [question] is the `?`. The [thenExpression] is the
  /// expression following the question mark. The [colon] is the `:`. The
  /// [elseExpression] is the expression following the colon.
  Expression conditionalExpression(Expression condition, Location question,
      Expression thenExpression, Location colon, Expression elseExpression);

  /// Return a representation of an `is` expression. The [operand] is the
  /// representation of the left operand. The [isOperator] is the `is` operator.
  /// The [notOperator] is either the `!` or `null` if the test is not negated.
  /// The [type] is a representation of the type that is the right operand.
  Expression isExpression(Expression operand, Location isOperator,
      Location notOperator, covariant type);

  Expression notExpression(Expression operand, Location location);

  Expression stringConcatenationExpression(
      List<Expression> expressions, Location location);

  Expression thisExpression(Location location);

  bool isErroneousNode(covariant node);

  // TODO(ahe): Remove this method when all users are moved here.
  kernel.Arguments castArguments(Arguments arguments) {
    dynamic a = arguments;
    return a;
  }
}
