// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transformer.wrapping_aggregate_transformer;

import 'dart:async';

import '../asset/asset_id.dart';
import '../utils.dart';
import 'aggregate_transform.dart';
import 'aggregate_transformer.dart';
import 'declaring_aggregate_transform.dart';
import 'declaring_aggregate_transformer.dart';
import 'declaring_transform.dart';
import 'declaring_transformer.dart';
import 'lazy_aggregate_transformer.dart';
import 'lazy_transformer.dart';
import 'transform.dart';
import 'transformer.dart';

/// An [AggregateTransformer] that wraps a non-aggregate [Transformer].
///
/// Although barback internally works in terms of [AggregateTransformer]s, most
/// transformers only work on individual primary inputs in isolation. We want to
/// allow those transformers to implement the more user-friendly [Transformer]
/// interface. This class makes that possible.
class WrappingAggregateTransformer implements AggregateTransformer {
  /// The wrapped transformer.
  final Transformer transformer;

  factory WrappingAggregateTransformer(Transformer transformer) {
    if (transformer is LazyTransformer) {
      return new _LazyWrappingAggregateTransformer(
          transformer as LazyTransformer);
    } else if (transformer is DeclaringTransformer) {
      return new _DeclaringWrappingAggregateTransformer(
          transformer as DeclaringTransformer);
    } else {
      return new WrappingAggregateTransformer._(transformer);
    }
  }

  WrappingAggregateTransformer._(this.transformer);

  Future<String> classifyPrimary(AssetId id) {
    return syncFuture(() => transformer.isPrimary(id))
        .then((isPrimary) => isPrimary ? id.path : null);
  }

  Future apply(AggregateTransform aggregateTransform) {
    return newTransform(aggregateTransform)
        .then((transform) => transformer.apply(transform));
  }

  String toString() => transformer.toString();
}

/// A wrapper for [DeclaringTransformer]s that implements
/// [DeclaringAggregateTransformer].
class _DeclaringWrappingAggregateTransformer
    extends WrappingAggregateTransformer
    implements DeclaringAggregateTransformer {
  final DeclaringTransformer _declaring;

  _DeclaringWrappingAggregateTransformer(DeclaringTransformer transformer)
      : _declaring = transformer,
        super._(transformer as Transformer);

  Future declareOutputs(DeclaringAggregateTransform aggregateTransform) {
    return newDeclaringTransform(aggregateTransform).then((transform) {
      return (transformer as DeclaringTransformer).declareOutputs(transform);
    });
  }
}

/// A wrapper for [LazyTransformer]s that implements
/// [LazyAggregateTransformer].
class _LazyWrappingAggregateTransformer
    extends _DeclaringWrappingAggregateTransformer
    implements LazyAggregateTransformer {
  _LazyWrappingAggregateTransformer(LazyTransformer transformer)
      : super(transformer);
}
