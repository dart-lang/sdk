// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_transformers.src.resolver_transformer;

import 'dart:async';
import 'package:barback/barback.dart';

import 'resolver.dart';
import 'resolver_impl.dart';

/// Filter for whether the specified asset is an entry point to the Dart
/// application.
typedef EntryPointFilter(Asset input);

/// Transformer which maintains up-to-date resolved ASTs for the specified
/// code entry points.
///
/// This can used by transformers dependent on resolved ASTs which can reference
/// this transformer to get the resolver needed.
///
/// This transformer must be in a phase before any dependent transformers. The
/// resolve AST is automatically updated any time any dependent assets are
/// changed.
///
/// This will only resolve the AST for code beginning from assets which are
/// accepted by [entryPointFilter].
///
/// If multiple transformers rely on a resolved AST they should (ideally) share
/// the same ResolverTransformer to avoid re-parsing the AST.
class ResolverTransformer extends Transformer {
  final Map<AssetId, Resolver> _resolvers = {};
  final EntryPointFilter entryPointFilter;
  final String dartSdkDirectory;

  ResolverTransformer(this.dartSdkDirectory, this.entryPointFilter);

  Future<bool> isPrimary(Asset input) =>
      new Future.value(entryPointFilter(input));

  /// Updates the resolved AST for the primary input of the transform.
  Future apply(Transform transform) {
    var resolver = getResolver(transform.primaryInput.id);

    return resolver.updateSources(transform).then((_) {
      transform.addOutput(transform.primaryInput);
      return null;
    });
  }

  /// Get a resolver for the AST starting from [id].
  Resolver getResolver(AssetId id) =>
      _resolvers.putIfAbsent(id, () => new ResolverImpl(id, dartSdkDirectory));
}
