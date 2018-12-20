// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.text_serializer;

import '../ast.dart';

import 'serializer_combinators.dart';

import '../visitor.dart' show ExpressionVisitor;

class ExpressionTagger extends ExpressionVisitor<String> {
  const ExpressionTagger();

  String visitStringLiteral(StringLiteral _) => "string";
  String visitIntLiteral(IntLiteral _) => "int";
  String visitDoubleLiteral(DoubleLiteral _) => "double";
  String visitBoolLiteral(BoolLiteral _) => "bool";
  String visitNullLiteral(NullLiteral _) => "null";
}

// ==== Serializers for BasicLiterals
const TextSerializer<BasicLiteral> basicLiteralSerializer = Case([
  "string",
  "int",
  "double",
  "bool",
  "null"
], [
  stringLiteralSerializer,
  intLiteralSerializer,
  doubleLiteralSerializer,
  boolLiteralSerializer,
  nullLiteralSerializer
]);

const TextSerializer<StringLiteral> stringLiteralSerializer =
    Wrapped(unwrapStringLiteral, wrapStringLiteral, DartString());

String unwrapStringLiteral(StringLiteral literal) => literal.value;

StringLiteral wrapStringLiteral(String value) => new StringLiteral(value);

const TextSerializer<IntLiteral> intLiteralSerializer =
    Wrapped(unwrapIntLiteral, wrapIntLiteral, DartInt());

int unwrapIntLiteral(IntLiteral literal) => literal.value;

IntLiteral wrapIntLiteral(int value) => new IntLiteral(value);

const TextSerializer<DoubleLiteral> doubleLiteralSerializer =
    Wrapped(unwrapDoubleLiteral, wrapDoubleLiteral, DartDouble());

double unwrapDoubleLiteral(DoubleLiteral literal) => literal.value;

DoubleLiteral wrapDoubleLiteral(double value) => new DoubleLiteral(value);

const TextSerializer<BoolLiteral> boolLiteralSerializer =
    Wrapped(unwrapBoolLiteral, wrapBoolLiteral, DartBool());

bool unwrapBoolLiteral(BoolLiteral literal) => literal.value;

BoolLiteral wrapBoolLiteral(bool value) => new BoolLiteral(value);

const TextSerializer<NullLiteral> nullLiteralSerializer =
    Wrapped(unwrapNullLiteral, wrapNullLiteral, Nothing());

void unwrapNullLiteral(NullLiteral literal) {}

NullLiteral wrapNullLiteral(void ignored) => new NullLiteral();
