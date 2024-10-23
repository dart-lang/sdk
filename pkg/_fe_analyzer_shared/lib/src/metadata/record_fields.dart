// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'expressions.dart';
import 'proto.dart';

/// Superclass for named and position record fields.
// TODO(johnniwinther): Merge subclasses into one class?
sealed class RecordField {
  /// Returns the [RecordField] corresponding to this [RecordField] in
  /// which all [UnresolvedIdentifier]s have been resolved within their scope.
  ///
  /// If this didn't create a new [RecordField], `null` is returned.
  RecordField? resolve();
}

class RecordNamedField extends RecordField {
  final String name;
  final Expression expression;

  RecordNamedField(this.name, this.expression);

  @override
  String toString() => 'RecordNamedField($name,$expression)';

  @override
  RecordField? resolve() {
    Expression? newExpression = expression.resolve();
    return newExpression == null
        ? null
        : new RecordNamedField(name, newExpression);
  }
}

class RecordPositionalField extends RecordField {
  final Expression expression;

  RecordPositionalField(this.expression);

  @override
  String toString() => 'RecordPositionalField($expression)';

  @override
  RecordField? resolve() {
    Expression? newExpression = expression.resolve();
    return newExpression == null
        ? null
        : new RecordPositionalField(newExpression);
  }
}
