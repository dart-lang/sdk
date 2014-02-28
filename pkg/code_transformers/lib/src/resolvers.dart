// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_transformers.src.resolvers;

import 'dart:async';
import 'package:barback/barback.dart' show AssetId, Transformer, Transform;

import 'resolver.dart';
import 'resolver_impl.dart';

/// Barback-based code resolvers which maintains up-to-date resolved ASTs for
/// the specified code entry points.
///
/// This can used by transformers dependent on resolved ASTs to handle the
/// resolution of the AST and cache the results between compilations.
///
/// If multiple transformers rely on a resolved AST they should (ideally) share
/// the same Resolvers object to minimize re-parsing the AST.
class Resolvers {
  final Map<AssetId, ResolverImpl> _resolvers = {};
  final String dartSdkDirectory;

  Resolvers(this.dartSdkDirectory);

  /// Get a resolver for the AST starting from [id].
  ///
  /// [Resolver.release] must be called once it's done being used, or
  /// [ResolverTransformer] should be used to automatically release the
  /// resolver.
  Future<Resolver> get(Transform transform) {
    var id = transform.primaryInput.id;
    var resolver = _resolvers.putIfAbsent(id,
        () => new ResolverImpl(id, dartSdkDirectory));
    return resolver.resolve(transform);
  }
}

/// Transformer mixin which automatically gets and releases resolvers.
///
/// To use mix this class in, set the resolvers field and override
/// [applyResolver].
abstract class ResolverTransformer implements Transformer {
  /// The cache of resolvers- must be set from subclass.
  Resolvers resolvers;

  Future apply(Transform transform) {
    return resolvers.get(transform).then((resolver) {
      return new Future.value(applyResolver(transform, resolver)).then((_) {
        resolver.release();
      });
    });
  }

  /// Invoked when the resolver is ready to be processed.
  ///
  /// Return a Future to indicate when apply is completed.
  applyResolver(Transform transform, Resolver resolver);
}
