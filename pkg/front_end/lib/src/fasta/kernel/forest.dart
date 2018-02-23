// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.forest;

/// A tree factory.
abstract class Forest<Expression, Statement> {
  Expression asLiteralString(Expression value);

  Expression literalBool(bool value, int offset);

  Expression literalDouble(double value, int offset);

  Expression literalInt(int value, int offset);

  Expression literalList(covariant typeArgument, List<Expression> expressions,
      bool isConst, int offset);

  Expression literalMap(covariant keyType, covariant valueType,
      covariant List entries, bool isConst, int offset);

  Expression literalNull(int offset);

  Expression literalString(String value, int offset);

  Expression literalSymbol(String value, int offset);

  Expression literalType(covariant type, int offset);

  Object mapEntry(Expression key, Expression value, int offset);

  List mapEntryList(int length);
}
