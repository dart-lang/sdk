// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.forest;

/// A tree factory.
abstract class Forest<Expression, Statement, Location> {
  Expression asLiteralString(Expression value);

  Expression literalBool(bool value, Location location);

  Expression literalDouble(double value, Location location);

  Expression literalInt(int value, Location location);

  Expression literalList(covariant typeArgument, List<Expression> expressions,
      bool isConst, Location location);

  Expression literalMap(covariant keyType, covariant valueType,
      covariant List entries, bool isConst, Location location);

  Expression literalNull(Location location);

  Expression literalString(String value, Location location);

  Expression literalSymbol(String value, Location location);

  Expression literalType(covariant type, Location location);

  Object mapEntry(Expression key, Expression value, Location location);

  List mapEntryList(int length);
}
