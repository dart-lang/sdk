// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.excluding_transformer;

import 'dart:async';

import 'package:barback/barback.dart';

/// Decorates an inner [Transformer] and handles including and excluding
/// primary inputs.
class ExcludingTransformer extends Transformer {
  /// If [includes] or [excludes] is non-null, wraps [inner] in an
  /// [ExcludingTransformer] that handles those.
  ///
  /// Otherwise, just returns [inner] unmodified.
  static Transformer wrap(Transformer inner, Set<String> includes,
      Set<String> excludes) {
    if (includes == null && excludes == null) return inner;

    return new ExcludingTransformer._(inner, includes, excludes);
  }

  final Transformer _inner;

  /// The set of asset paths which should be included.
  ///
  /// If `null`, all non-excluded assets are allowed. Otherwise, only included
  /// assets are allowed.
  final Set<String> _includes;

  /// The set of assets which should be excluded.
  ///
  /// Exclusions are applied after inclusions.
  final Set<String> _excludes;

  ExcludingTransformer._(this._inner, this._includes, this._excludes);

  Future<bool> isPrimary(Asset asset) {
    // TODO(rnystrom): Support globs in addition to paths. See #17093.
    if (_includes != null) {
      // If there are any includes, it must match one of them.
      if (!_includes.contains(asset.id.path)) return new Future.value(false);
    }

    // It must not be excluded.
    if (_excludes != null && _excludes.contains(asset.id.path)) {
      return new Future.value(false);
    }

    return _inner.isPrimary(asset);
  }

  Future apply(Transform transform) => _inner.apply(transform);

  String toString() => _inner.toString();
}
