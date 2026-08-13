// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'expressions.dart';
import 'proto.dart';

/// Superclass for named and position arguments.
// TODO(johnniwinther): Merge subclasses into one class?
sealed class Argument {
  /// Returns the [Argument] corresponding to this [Argument] in
  /// which all [UnresolvedIdentifier]s have been resolved within their scope.
  ///
  /// If this didn't create a new [Argument], `null` is returned.
  Argument? resolve();
}

class PositionalArgument extends Argument {
  final Expression expression;

  PositionalArgument(this.expression);

  @override
  String toString() => 'PositionalArgument($expression)';

  @override
  Argument? resolve() {
    Expression? newExpression = expression.resolve();
    return newExpression == null ? null : new PositionalArgument(newExpression);
  }
}

class NamedArgument extends Argument {
  final String name;
  final Expression expression;

  NamedArgument(this.name, this.expression);

  @override
  String toString() => 'NamedArgument($name,$expression)';

  @override
  Argument? resolve() {
    Expression? newExpression = expression.resolve();
    return newExpression == null
        ? null
        : new NamedArgument(name, newExpression);
  }
}
