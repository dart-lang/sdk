// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.fangorn;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart' show DartType, MapEntry;

import 'package:kernel/ast.dart' as kernel;

import '../parser.dart' show offsetForToken;

import '../scanner.dart' show Token;

import 'kernel_shadow_ast.dart';

import 'forest.dart' show Forest;

/// A shadow tree factory.
class Fangorn extends Forest<ShadowExpression, ShadowStatement, Token> {
  @override
  ShadowStringLiteral asLiteralString(ShadowExpression value) => value;

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
  ShadowExpression literalList(covariant typeArgument,
      List<kernel.Expression> expressions, bool isConst, Token token) {
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
  MapEntry mapEntry(ShadowExpression key, ShadowExpression value, Token token) {
    return new MapEntry(key, value)..fileOffset = offsetForToken(token);
  }

  @override
  List<MapEntry> mapEntryList(int length) {
    return new List<MapEntry>.filled(length, null, growable: true);
  }
}
