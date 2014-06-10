// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.excluding_aggregate_transformer;

import 'dart:async';

import 'package:barback/barback.dart';

/// Decorates an inner [AggregateTransformer] and handles including and
/// excluding primary inputs.
class ExcludingAggregateTransformer extends AggregateTransformer {
  /// If [includes] or [excludes] is non-null, wraps [inner] in an
  /// [ExcludingAggregateTransformer] that handles those.
  ///
  /// Otherwise, just returns [inner] unmodified.
  static AggregateTransformer wrap(AggregateTransformer inner,
      Set<String> includes, Set<String> excludes) {
    if (includes == null && excludes == null) return inner;

    if (inner is LazyAggregateTransformer) {
      return new _LazyExcludingAggregateTransformer(
          inner as LazyAggregateTransformer, includes, excludes);
    } else if (inner is DeclaringAggregateTransformer) {
      return new _DeclaringExcludingAggregateTransformer(
          inner as DeclaringAggregateTransformer, includes, excludes);
    } else {
      return new ExcludingAggregateTransformer._(inner, includes, excludes);
    }
  }

  final AggregateTransformer _inner;

  /// The set of asset paths which should be included.
  ///
  /// If `null`, all non-excluded assets are allowed. Otherwise, only included
  /// assets are allowed.
  final Set<String> _includes;

  /// The set of assets which should be excluded.
  ///
  /// Exclusions are applied after inclusions.
  final Set<String> _excludes;

  ExcludingAggregateTransformer._(this._inner, this._includes, this._excludes);

  classifyPrimary(AssetId id) {
    // TODO(rnystrom): Support globs in addition to paths. See #17093.
    if (_includes != null) {
      // If there are any includes, it must match one of them.
      if (!_includes.contains(id.path)) return null;
    }

    // It must not be excluded.
    if (_excludes != null && _excludes.contains(id.path)) {
      return null;
    }

    return _inner.classifyPrimary(id);
  }

  Future apply(AggregateTransform transform) => _inner.apply(transform);

  String toString() => _inner.toString();
}

class _DeclaringExcludingAggregateTransformer
    extends ExcludingAggregateTransformer
    implements DeclaringAggregateTransformer {
  _DeclaringExcludingAggregateTransformer(DeclaringAggregateTransformer inner,
        Set<String> includes, Set<String> excludes)
      : super._(inner as AggregateTransformer, includes, excludes);

  Future declareOutputs(DeclaringAggregateTransform transform) =>
      (_inner as DeclaringAggregateTransformer).declareOutputs(transform);
}

class _LazyExcludingAggregateTransformer
    extends _DeclaringExcludingAggregateTransformer
    implements LazyAggregateTransformer {
  _LazyExcludingAggregateTransformer(DeclaringAggregateTransformer inner,
        Set<String> includes, Set<String> excludes)
      : super(inner, includes, excludes);
}
