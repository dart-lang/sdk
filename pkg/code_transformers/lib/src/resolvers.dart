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
  final Map<AssetId, Resolver> _resolvers = {};
  final String dartSdkDirectory;

  Resolvers(this.dartSdkDirectory);

  /// Get a resolver for [transform]. If provided, this resolves the code
  /// starting from each of the assets in [entryPoints]. If not, this resolves
  /// the code starting from `transform.primaryInput.id` by default.
  ///
  /// [Resolver.release] must be called once it's done being used, or
  /// [ResolverTransformer] should be used to automatically release the
  /// resolver.
  Future<Resolver> get(Transform transform, [List<AssetId> entryPoints]) {
    var id = transform.primaryInput.id;
    var resolver = _resolvers.putIfAbsent(id,
        () => new ResolverImpl(dartSdkDirectory));
    return resolver.resolve(transform, entryPoints);
  }
}

/// Transformer mixin which automatically gets and releases resolvers.
///
/// To use mix this class in, set the resolvers field and override
/// [applyResolver].
abstract class ResolverTransformer implements Transformer {
  /// The cache of resolvers- must be set from subclass.
  Resolvers resolvers;

  /// This provides a default implementation of `Transformer.apply` that will
  /// get and release resolvers automatically. Internally this:
  ///   * Gets a resolver associated with the transform primary input.
  ///   * Does resolution to the code starting from that input.
  ///   * Calls [applyResolver].
  ///   * Then releases the resolver.
  ///
  /// Use [applyToEntryPoints] instead if you need to override the entry points
  /// to run the resolver on.
  Future apply(Transform transform) => applyToEntryPoints(transform);

  /// Helper function to make it easy to write an `Transformer.apply` method
  /// that automatically gets and releases the resolver. This is typically used
  /// as follows:
  ///
  ///    Future apply(Transform transform) {
  ///       var entryPoints = ...; // compute entry points
  ///       return applyToEntryPoints(transform, entryPoints);
  ///    }
  Future applyToEntryPoints(Transform transform, [List<AssetId> entryPoints]) {
    return resolvers.get(transform, entryPoints).then((resolver) {
      return new Future(() => applyResolver(transform, resolver))
        .whenComplete(() {
          resolver.release();
        });
    });
  }

  /// Invoked when the resolver is ready to be processed.
  ///
  /// Return a Future to indicate when apply is completed.
  applyResolver(Transform transform, Resolver resolver);
}
