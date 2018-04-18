// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.forest;

// TODO(ahe): Remove this import.
import 'package:kernel/ast.dart' as kernel show Arguments;

/// A tree factory.
abstract class Forest<Expression, Statement, Location, Arguments> {
  Arguments arguments(List<Expression> positional, Location location,
      {covariant List types, covariant List named});

  Arguments argumentsEmpty(Location location);

  List argumentsNamed(Arguments arguments);

  List<Expression> argumentsPositional(Arguments arguments);

  List argumentsTypeArguments(Arguments arguments);

  void argumentsSetTypeArguments(Arguments arguments, covariant List types);

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

  int readOffset(covariant node);

  Expression loadLibrary(covariant dependency);

  Expression checkLibraryIsLoaded(covariant dependency);

  bool isErroneousNode(covariant node);

  // TODO(ahe): Remove this method when all users are moved here.
  kernel.Arguments castArguments(Arguments arguments) {
    dynamic a = arguments;
    return a;
  }
}
