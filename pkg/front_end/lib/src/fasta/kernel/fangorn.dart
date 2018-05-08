// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.fangorn;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart'
    show
        Arguments,
        DartType,
        Expression,
        ExpressionStatement,
        InvalidExpression,
        Let,
        LibraryDependency,
        MapEntry,
        NamedExpression,
        Statement,
        TreeNode,
        VariableDeclaration;

import '../parser.dart' show offsetForToken;

import '../scanner.dart' show Token;

import 'kernel_shadow_ast.dart'
    show
        ShadowArguments,
        ShadowAsExpression,
        ShadowAwaitExpression,
        ShadowBoolLiteral,
        ShadowCheckLibraryIsLoaded,
        ShadowConditionalExpression,
        ShadowDoubleLiteral,
        ShadowIntLiteral,
        ShadowIsExpression,
        ShadowIsNotExpression,
        ShadowListLiteral,
        ShadowLoadLibrary,
        ShadowMapLiteral,
        ShadowNot,
        ShadowNullLiteral,
        ShadowStringConcatenation,
        ShadowStringLiteral,
        ShadowSymbolLiteral,
        ShadowSyntheticExpression,
        ShadowThisExpression,
        ShadowTypeLiteral;

import 'forest.dart' show Forest;

/// A shadow tree factory.
class Fangorn extends Forest<Expression, Statement, Token, Arguments> {
  @override
  ShadowArguments arguments(List<Expression> positional, Token token,
      {List<DartType> types, List<NamedExpression> named}) {
    return new ShadowArguments(positional, types: types, named: named)
      ..fileOffset = offsetForToken(token);
  }

  @override
  ShadowArguments argumentsEmpty(Token token) {
    return arguments(<Expression>[], token);
  }

  @override
  List<NamedExpression> argumentsNamed(Arguments arguments) {
    return arguments.named;
  }

  @override
  List<Expression> argumentsPositional(Arguments arguments) {
    return arguments.positional;
  }

  @override
  List<DartType> argumentsTypeArguments(Arguments arguments) {
    return arguments.types;
  }

  @override
  void argumentsSetTypeArguments(Arguments arguments, List<DartType> types) {
    ShadowArguments.setNonInferrableArgumentTypes(arguments, types);
  }

  @override
  ShadowStringLiteral asLiteralString(Expression value) => value;

  @override
  ShadowBoolLiteral literalBool(bool value, Token token) {
    return new ShadowBoolLiteral(value)..fileOffset = offsetForToken(token);
  }

  @override
  ShadowDoubleLiteral literalDouble(double value, Token token) {
    return new ShadowDoubleLiteral(value)..fileOffset = offsetForToken(token);
  }

  @override
  ShadowIntLiteral literalInt(int value, Token token) {
    return new ShadowIntLiteral(value)..fileOffset = offsetForToken(token);
  }

  @override
  ShadowListLiteral literalList(
      Token constKeyword,
      bool isConst,
      Object typeArgument,
      Object typeArguments,
      Token leftBracket,
      List<Expression> expressions,
      Token rightBracket) {
    // TODO(brianwilkerson): The file offset computed below will not be correct
    // if there are type arguments but no `const` keyword.
    return new ShadowListLiteral(expressions,
        typeArgument: typeArgument, isConst: isConst)
      ..fileOffset = offsetForToken(constKeyword ?? leftBracket);
  }

  @override
  ShadowMapLiteral literalMap(
      Token constKeyword,
      bool isConst,
      DartType keyType,
      DartType valueType,
      Object typeArguments,
      Token leftBracket,
      List<MapEntry> entries,
      Token rightBracket) {
    // TODO(brianwilkerson): The file offset computed below will not be correct
    // if there are type arguments but no `const` keyword.
    return new ShadowMapLiteral(entries,
        keyType: keyType, valueType: valueType, isConst: isConst)
      ..fileOffset = offsetForToken(constKeyword ?? leftBracket);
  }

  @override
  ShadowNullLiteral literalNull(Token token) {
    return new ShadowNullLiteral()..fileOffset = offsetForToken(token);
  }

  @override
  ShadowStringLiteral literalString(String value, Token token) {
    return new ShadowStringLiteral(value)..fileOffset = offsetForToken(token);
  }

  @override
  ShadowSymbolLiteral literalSymbol(String value, Token token) {
    return new ShadowSymbolLiteral(value)..fileOffset = offsetForToken(token);
  }

  @override
  ShadowTypeLiteral literalType(DartType type, Token token) {
    return new ShadowTypeLiteral(type)..fileOffset = offsetForToken(token);
  }

  @override
  MapEntry mapEntry(Expression key, Token colon, Expression value) {
    return new MapEntry(key, value)..fileOffset = offsetForToken(colon);
  }

  @override
  List<MapEntry> mapEntryList(int length) {
    return new List<MapEntry>.filled(length, null, growable: true);
  }

  @override
  int readOffset(TreeNode node) => node.fileOffset;

  @override
  int getTypeCount(Object typeArguments) => (typeArguments as List).length;

  @override
  DartType getTypeAt(Object typeArguments, int index) =>
      (typeArguments as List)[index];

  @override
  Expression loadLibrary(LibraryDependency dependency) {
    return new ShadowLoadLibrary(dependency);
  }

  @override
  Expression checkLibraryIsLoaded(LibraryDependency dependency) {
    return new ShadowCheckLibraryIsLoaded(dependency);
  }

  @override
  Expression asExpression(Expression expression, covariant type, Token token) {
    return new ShadowAsExpression(expression, type)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression awaitExpression(Expression operand, Token token) {
    return new ShadowAwaitExpression(operand)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression conditionalExpression(Expression condition, Token question,
      Expression thenExpression, Token colon, Expression elseExpression) {
    return new ShadowConditionalExpression(
        condition, thenExpression, elseExpression)
      ..fileOffset = offsetForToken(question);
  }

  @override
  Expression isExpression(
      Expression operand, isOperator, Token notOperator, covariant type) {
    int offset = offsetForToken(isOperator);
    if (notOperator != null) {
      return new ShadowIsNotExpression(operand, type, offset);
    }
    return new ShadowIsExpression(operand, type)..fileOffset = offset;
  }

  @override
  Expression notExpression(Expression operand, Token token) {
    return new ShadowNot(operand)..fileOffset = offsetForToken(token);
  }

  @override
  Expression stringConcatenationExpression(
      List<Expression> expressions, Token token) {
    return new ShadowStringConcatenation(expressions)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression thisExpression(Token token) {
    return new ShadowThisExpression()..fileOffset = offsetForToken(token);
  }

  @override
  bool isErroneousNode(TreeNode node) {
    if (node is ExpressionStatement) {
      ExpressionStatement statement = node;
      node = statement.expression;
    }
    if (node is VariableDeclaration) {
      VariableDeclaration variable = node;
      node = variable.initializer;
    }
    if (node is ShadowSyntheticExpression) {
      ShadowSyntheticExpression synth = node;
      node = synth.desugared;
    }
    if (node is Let) {
      Let let = node;
      node = let.variable.initializer;
    }
    return node is InvalidExpression;
  }
}
