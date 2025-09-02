// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'expressions.dart';
import 'proto.dart';

/// Superclass for collection elements.
sealed class Element {
  /// Returns the [Element] corresponding to this [Element] in
  /// which all [UnresolvedIdentifier]s have been resolved within their scope.
  ///
  /// If this didn't create a new [Element], `null` is returned.
  Element? resolve();
}

class ExpressionElement extends Element {
  final Expression expression;
  final bool isNullAware;

  ExpressionElement(this.expression, {required this.isNullAware});

  @override
  String toString() =>
      'ExpressionElement($expression,isNullAware=$isNullAware)';

  @override
  Element? resolve() {
    Expression? newExpression = expression.resolve();
    return newExpression == null
        ? null
        : new ExpressionElement(newExpression, isNullAware: isNullAware);
  }
}

class MapEntryElement extends Element {
  final Expression key;
  final Expression value;
  final bool isNullAwareKey;
  final bool isNullAwareValue;

  MapEntryElement(
    this.key,
    this.value, {
    required this.isNullAwareKey,
    required this.isNullAwareValue,
  });

  @override
  String toString() =>
      'MapEntryElement($key,$value,'
      'isNullAwareKey=$isNullAwareValue,isNullAwareValue=$isNullAwareValue)';

  @override
  Element? resolve() {
    Expression? newKey = key.resolve();
    Expression? newValue = value.resolve();
    return newKey == null && newValue == null
        ? null
        : new MapEntryElement(
            newKey ?? key,
            newValue ?? value,
            isNullAwareKey: isNullAwareKey,
            isNullAwareValue: isNullAwareValue,
          );
  }
}

class SpreadElement extends Element {
  final Expression expression;
  final bool isNullAware;

  SpreadElement(this.expression, {required this.isNullAware});

  @override
  String toString() => 'SpreadElement($expression,isNullAware=$isNullAware)';

  @override
  Element? resolve() {
    Expression? newExpression = expression.resolve();
    return newExpression == null
        ? null
        : new SpreadElement(newExpression, isNullAware: isNullAware);
  }
}

class IfElement extends Element {
  final Expression condition;
  final Element then;
  final Element? otherwise;

  IfElement(this.condition, this.then, [this.otherwise]);

  @override
  String toString() => 'IfElement($condition,$then,$otherwise)';

  @override
  Element? resolve() {
    Expression? newCondition = condition.resolve();
    Element? newThen = then.resolve();
    Element? newOtherwise = otherwise?.resolve();
    if (otherwise != null) {
      return newCondition == null && newThen == null && newOtherwise == null
          ? null
          : new IfElement(
              newCondition ?? condition,
              newThen ?? then,
              newOtherwise ?? otherwise,
            );
    } else {
      return newCondition == null && newThen == null
          ? null
          : new IfElement(newCondition ?? condition, newThen ?? then);
    }
  }
}
