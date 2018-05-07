// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:front_end/src/fasta/kernel/forest.dart';
import 'package:kernel/ast.dart' as kernel;

/// An implementation of a [Forest] that can be used to build an AST structure.
class AstBuildingForest
    implements Forest<Expression, Statement, Token, _Arguments> {
  /// The factory used to create AST nodes.
  AstFactoryImpl astFactory = new AstFactoryImpl();

  /// Initialize a newly created AST-building forest.
  AstBuildingForest();

  @override
  _Arguments arguments(List<Expression> positional, Token location,
      {covariant List types, covariant List named}) {
    _Arguments arguments = new _Arguments();
    if (types != null) {
      arguments.typeArguments = types.cast<TypeAnnotation>();
    }
    arguments.positionalArguments = positional.cast<Expression>();
    if (named != null) {
      arguments.namedArguments = named.cast<Expression>();
    }
    return arguments;
  }

  @override
  _Arguments argumentsEmpty(Token location) => new _Arguments();

  @override
  List argumentsNamed(_Arguments arguments) => arguments.namedArguments;

  @override
  List<Expression> argumentsPositional(_Arguments arguments) =>
      arguments.positionalArguments;

  @override
  void argumentsSetTypeArguments(_Arguments arguments, covariant List types) {
    arguments.typeArguments = types.cast<TypeAnnotation>();
  }

  @override
  List argumentsTypeArguments(_Arguments arguments) => arguments.typeArguments;

  @override
  Expression asExpression(Expression expression, type, Token location) =>
      astFactory.asExpression(expression, location, type);

  Expression asLiteralString(Expression value) => value;

  @override
  Expression awaitExpression(Expression operand, Token awaitKeyword) {
    return astFactory.awaitExpression(awaitKeyword, operand);
  }

  @override
  kernel.Arguments castArguments(_Arguments arguments) {
    // TODO(brianwilkerson) Implement this or remove it from the API.
    throw new UnimplementedError();
  }

  @override
  Expression checkLibraryIsLoaded(dependency) {
    // TODO(brianwilkerson) Implement this.
    throw new UnimplementedError();
  }

  @override
  Expression conditionalExpression(Expression condition, Token question,
          Expression thenExpression, Token colon, Expression elseExpression) =>
      astFactory.conditionalExpression(
          condition, question, thenExpression, colon, elseExpression);

  @override
  kernel.DartType getTypeAt(Object typeArguments, int index) {
    return null; // (typeArguments as TypeArgumentList).arguments[index].type.kernelType;
  }

  @override
  int getTypeCount(Object typeArguments) {
    return (typeArguments as TypeArgumentList).arguments.length;
  }

  @override
  bool isErroneousNode(covariant node) => false; // ???

  @override
  Expression isExpression(Expression expression, Token isOperator,
          Token notOperator, Object type) =>
      astFactory.isExpression(expression, isOperator, notOperator, type);

  @override
  Expression literalBool(bool value, Token location) =>
      astFactory.booleanLiteral(location, value);

  @override
  Expression literalDouble(double value, Token location) =>
      astFactory.doubleLiteral(location, value);

  @override
  Expression literalInt(int value, Token location) =>
      astFactory.integerLiteral(location, value);

  @override
  Expression literalList(
          Token constKeyword,
          bool isConst,
          Object typeArgument,
          Object typeArguments,
          Token leftBracket,
          List<Expression> expressions,
          Token rightBracket,
          Token location) =>
      astFactory.listLiteral(
          constKeyword, typeArguments, leftBracket, expressions, rightBracket);

  @override
  Expression literalMap(
          Token constKeyword,
          bool isConst,
          covariant keyType,
          covariant valueType,
          Object typeArguments,
          Token leftBracket,
          covariant List entries,
          Token rightBracket,
          Token location) =>
      astFactory.mapLiteral(
          constKeyword, typeArguments, leftBracket, entries, rightBracket);

  @override
  Expression literalNull(Token location) => astFactory.nullLiteral(location);

  @override
  Expression literalString(String value, Token location) =>
      astFactory.simpleStringLiteral(location, value);

  @override
  Expression literalSymbol(String value, Token location) {
    // TODO(brianwilkerson) Get the missing information.
    return astFactory.symbolLiteral(location, null /* components */);
  }

  @override
  Expression literalType(covariant type, Token location) {
    // TODO(brianwilkerson) Capture the type information.
    return astFactory.simpleIdentifier(location);
  }

  @override
  Expression loadLibrary(dependency) {
    // TODO(brianwilkerson) Implement this.
    throw new UnimplementedError();
  }

  @override
  Object mapEntry(Expression key, Token colon, Expression value) =>
      astFactory.mapLiteralEntry(key, colon, value);

  @override
  List mapEntryList(int length) => <MapLiteralEntry>[];

  @override
  Expression notExpression(Expression operand, Token operator) =>
      astFactory.prefixExpression(operator, operand);

  @override
  int readOffset(AstNode node) => node.offset;

  @override
  Expression stringConcatenationExpression(
          List<Expression> strings, Token location) =>
      astFactory.adjacentStrings(strings);

  @override
  Expression thisExpression(Token thisKeyword) =>
      astFactory.thisExpression(thisKeyword);
}

/// A data holder used to conform to the [Forest] API.
class _Arguments {
  List<TypeAnnotation> typeArguments = <TypeAnnotation>[];
  List<Expression> positionalArguments = <Expression>[];
  List<Expression> namedArguments = <Expression>[];
}
