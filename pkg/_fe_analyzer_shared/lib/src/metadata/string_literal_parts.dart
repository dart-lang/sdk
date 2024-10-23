// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'expressions.dart';
import 'proto.dart';

/// Superclass for parts of a string literal.
sealed class StringLiteralPart {
  /// Returns the [StringLiteralPart] corresponding to this [StringLiteralPart]
  /// in which all [UnresolvedIdentifier]s have been resolved within their
  /// scope.
  ///
  /// If this didn't create a new [StringLiteralPart], `null` is returned.
  StringLiteralPart? resolve();
}

class StringPart extends StringLiteralPart {
  final String text;

  StringPart(this.text);

  @override
  String toString() => 'StringPart($text)';

  @override
  StringLiteralPart? resolve() => null;
}

class InterpolationPart extends StringLiteralPart {
  final Expression expression;

  InterpolationPart(this.expression);

  @override
  String toString() => 'InterpolationPart($expression)';

  @override
  StringLiteralPart? resolve() {
    Expression? newExpression = expression.resolve();
    return newExpression == null ? null : new InterpolationPart(newExpression);
  }
}
