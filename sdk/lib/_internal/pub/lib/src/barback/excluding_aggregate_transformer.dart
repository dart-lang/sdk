// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.excluding_aggregate_transformer;

import 'dart:async';

import 'package:barback/barback.dart';

import '../barback.dart';

/// Decorates an inner [AggregateTransformer] and handles including and
/// excluding primary inputs.
class ExcludingAggregateTransformer extends AggregateTransformer {
  /// If [id] defines includes or excludes, wraps [inner] in an
  /// [ExcludingAggregateTransformer] that handles those.
  ///
  /// Otherwise, just returns [inner] unmodified.
  static AggregateTransformer wrap(AggregateTransformer inner,
      TransformerId id) {
    if (!id.hasExclusions) return inner;

    if (inner is LazyAggregateTransformer) {
      return new _LazyExcludingAggregateTransformer(
          inner as LazyAggregateTransformer, id);
    } else if (inner is DeclaringAggregateTransformer) {
      return new _DeclaringExcludingAggregateTransformer(
          inner as DeclaringAggregateTransformer, id);
    } else {
      return new ExcludingAggregateTransformer._(inner, id);
    }
  }

  final AggregateTransformer _inner;

  /// The id containing rules for which assets to include or exclude.
  final TransformerId _id;

  ExcludingAggregateTransformer._(this._inner, this._id);

  classifyPrimary(AssetId id) {
    if (!_id.canTransform(id.path)) return null;
    return _inner.classifyPrimary(id);
  }

  Future apply(AggregateTransform transform) => _inner.apply(transform);

  String toString() => _inner.toString();
}

class _DeclaringExcludingAggregateTransformer
    extends ExcludingAggregateTransformer
    implements DeclaringAggregateTransformer {
  _DeclaringExcludingAggregateTransformer(DeclaringAggregateTransformer inner,
        TransformerId id)
      : super._(inner as AggregateTransformer, id);

  Future declareOutputs(DeclaringAggregateTransform transform) =>
      (_inner as DeclaringAggregateTransformer).declareOutputs(transform);
}

class _LazyExcludingAggregateTransformer
    extends _DeclaringExcludingAggregateTransformer
    implements LazyAggregateTransformer {
  _LazyExcludingAggregateTransformer(DeclaringAggregateTransformer inner,
        TransformerId id)
      : super(inner, id);
}
