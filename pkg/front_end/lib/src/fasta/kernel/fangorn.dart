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
        MapEntry,
        NamedExpression,
        Statement,
        TreeNode;

import '../parser.dart' show offsetForToken;

import '../scanner.dart' show Token;

import 'kernel_shadow_ast.dart'
    show
        ShadowArguments,
        ShadowBoolLiteral,
        ShadowDoubleLiteral,
        ShadowIntLiteral,
        ShadowListLiteral,
        ShadowMapLiteral,
        ShadowNullLiteral,
        ShadowStringLiteral,
        ShadowSymbolLiteral,
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
  ShadowListLiteral literalList(covariant typeArgument,
      List<Expression> expressions, bool isConst, Token token) {
    return new ShadowListLiteral(expressions,
        typeArgument: typeArgument, isConst: isConst)
      ..fileOffset = offsetForToken(token);
  }

  @override
  ShadowMapLiteral literalMap(DartType keyType, DartType valueType,
      List<MapEntry> entries, bool isConst, Token token) {
    return new ShadowMapLiteral(entries,
        keyType: keyType, valueType: valueType, isConst: isConst)
      ..fileOffset = offsetForToken(token);
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
  MapEntry mapEntry(Expression key, Expression value, Token token) {
    return new MapEntry(key, value)..fileOffset = offsetForToken(token);
  }

  @override
  List<MapEntry> mapEntryList(int length) {
    return new List<MapEntry>.filled(length, null, growable: true);
  }

  @override
  int readOffset(TreeNode node) => node.fileOffset;
}
