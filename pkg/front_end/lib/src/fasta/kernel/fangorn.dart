// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.fangorn;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart' show DartType, MapEntry;

import 'package:kernel/ast.dart' as kernel;

import 'kernel_shadow_ast.dart';

import 'forest.dart' show Forest;

/// A shadow tree factory.
class Fangorn extends Forest<ShadowExpression, ShadowStatement> {
  @override
  ShadowStringLiteral asLiteralString(ShadowExpression value) => value;

  @override
  ShadowBoolLiteral literalBool(bool value, int offset) {
    return new ShadowBoolLiteral(value)..fileOffset = offset;
  }

  @override
  ShadowDoubleLiteral literalDouble(double value, int offset) {
    return new ShadowDoubleLiteral(value)..fileOffset = offset;
  }

  @override
  ShadowIntLiteral literalInt(int value, int offset) {
    return new ShadowIntLiteral(value)..fileOffset = offset;
  }

  @override
  ShadowExpression literalList(covariant typeArgument,
      List<kernel.Expression> expressions, bool isConst, int offset) {
    return new ShadowListLiteral(expressions,
        typeArgument: typeArgument, isConst: isConst)
      ..fileOffset = offset;
  }

  @override
  ShadowMapLiteral literalMap(DartType keyType, DartType valueType,
      List<MapEntry> entries, bool isConst, int offset) {
    return new ShadowMapLiteral(entries,
        keyType: keyType, valueType: valueType, isConst: isConst)
      ..fileOffset = offset;
  }

  @override
  ShadowNullLiteral literalNull(int offset) {
    return new ShadowNullLiteral()..fileOffset = offset;
  }

  @override
  ShadowStringLiteral literalString(String value, int offset) {
    return new ShadowStringLiteral(value)..fileOffset = offset;
  }

  @override
  ShadowSymbolLiteral literalSymbol(String value, int offset) {
    return new ShadowSymbolLiteral(value)..fileOffset = offset;
  }

  @override
  ShadowTypeLiteral literalType(DartType type, int offset) {
    return new ShadowTypeLiteral(type)..fileOffset = offset;
  }

  @override
  MapEntry mapEntry(ShadowExpression key, ShadowExpression value, int offset) {
    return new MapEntry(key, value)..fileOffset = offset;
  }

  @override
  List<MapEntry> mapEntryList(int length) {
    return new List<MapEntry>.filled(length, null, growable: true);
  }
}
