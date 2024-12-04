// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that multiple comparisons involving the same uint32 value
// with different constants do not generate multiple IntConverter
// instructions, only a sequence of 'Branch(EqualityCompare(...))'.
// Regression test for https://github.com/dart-lang/sdk/issues/56839.

import 'package:vm/testing/il_matchers.dart';

class Token {
  Token(TokenType type, int offset)
      : typeAndOffset = ((offset << 8) | type.index);

  int typeAndOffset;

  int get typeIndex => typeAndOffset & 0xff;
}

class TokenType {
  static const TokenType T10 = const TokenType(10, 'T10');
  static const TokenType T20 = const TokenType(20, 'T20');
  static const TokenType T30 = const TokenType(30, 'T30');
  static const TokenType T40 = const TokenType(40, 'T40');
  static const TokenType T50 = const TokenType(50, 'T50');
  static const TokenType T60 = const TokenType(50, 'T60');
  static const TokenType T70 = const TokenType(50, 'T70');

  const TokenType(this.index, this.name);

  final int index;
  final String name;
}

extension TokenIsAExtension on Token {
  @pragma("vm:prefer-inline")
  bool isA(TokenType value) {
    return value.index == typeIndex;
  }
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
bool looksLikeExpressionStart(Token next) =>
    next.isA(TokenType.T10) ||
    next.isA(TokenType.T20) ||
    next.isA(TokenType.T30) ||
    next.isA(TokenType.T40) ||
    next.isA(TokenType.T50);

void matchIL$looksLikeExpressionStart(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'int 255' << match.UnboxedConstant(value: 255),
      'int 10' << match.UnboxedConstant(value: 10),
      'int 20' << match.UnboxedConstant(value: 20),
      'int 30' << match.UnboxedConstant(value: 30),
      'int 40' << match.UnboxedConstant(value: 40),
      'int 50' << match.UnboxedConstant(value: 50),
    ]),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      'typeAndOffset' << match.LoadField(slot: 'typeAndOffset'),
      'typeAndOffset_u32' <<
          match.IntConverter('typeAndOffset', from: 'int64', to: 'uint32'),
      'typeIndex' <<
          match.BinaryUint32Op('typeAndOffset_u32', 'int 255', op_kind: '&'),
      match.Branch(match.EqualityCompare('typeIndex', 'int 10', kind: '=='),
          ifTrue: 'B9', ifFalse: 'B4'),
    ]),
    'B9' <<
        match.block('Target', [
          match.Goto('B8'),
        ]),
    'B4' <<
        match.block('Target', [
          match.Branch(match.EqualityCompare('typeIndex', 'int 20', kind: '=='),
              ifTrue: 'B10', ifFalse: 'B5'),
        ]),
    'B10' <<
        match.block('Target', [
          match.Goto('B8'),
        ]),
    'B5' <<
        match.block('Target', [
          match.Branch(match.EqualityCompare('typeIndex', 'int 30', kind: '=='),
              ifTrue: 'B11', ifFalse: 'B6'),
        ]),
    'B11' <<
        match.block('Target', [
          match.Goto('B8'),
        ]),
    'B6' <<
        match.block('Target', [
          match.Branch(match.EqualityCompare('typeIndex', 'int 40', kind: '=='),
              ifTrue: 'B12', ifFalse: 'B7'),
        ]),
    'B12' <<
        match.block('Target', [
          match.Goto('B8'),
        ]),
    'B8' <<
        match.block('Join', [
          match.Goto('B3'),
        ]),
    'B7' <<
        match.block('Target', [
          'v23' << match.EqualityCompare('typeIndex', 'int 50', kind: '=='),
          match.Goto('B3'),
        ]),
    'B3' <<
        match.block('Join', [
          'v14' << match.Phi('v23', match.any),
          match.DartReturn('v14'),
        ]),
  ]);
}

void main() {
  looksLikeExpressionStart(Token(TokenType.T10, 5));
  looksLikeExpressionStart(Token(TokenType.T60, 10));
}
