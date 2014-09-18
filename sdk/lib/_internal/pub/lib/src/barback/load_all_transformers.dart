// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.load_all_transformers;

import 'dart:async';

import '../log.dart' as log;
import '../package_graph.dart';
import '../utils.dart';
import 'asset_environment.dart';
import 'barback_server.dart';
import 'rewrite_import_transformer.dart';
import 'transformer_cache.dart';
import 'transformer_id.dart';
import 'transformer_loader.dart';
import 'transformers_needed_by_transformers.dart';

/// Loads all transformers depended on by packages in [environment].
///
/// This uses [environment]'s primary server to serve the Dart files from which
/// transformers are loaded, then adds the transformers to
/// `environment.barback`.
///
/// Any built-in transformers that are provided by the environment will
/// automatically be added to the end of the root package's cascade.
Future loadAllTransformers(AssetEnvironment environment,
    BarbackServer transformerServer) async {
  var transformersNeededByTransformers =
      computeTransformersNeededByTransformers(environment.graph,
          packages: environment.packages);

  var buffer = new StringBuffer();
  buffer.writeln("Transformer dependencies:");
  transformersNeededByTransformers.forEach((id, dependencies) {
    if (dependencies.isEmpty) {
      buffer.writeln("$id: -");
    } else {
      buffer.writeln("$id: ${toSentence(dependencies)}");
    }
  });
  log.fine(buffer);

  var stagedTransformers = _stageTransformers(transformersNeededByTransformers);

  var packagesThatUseTransformers =
      _packagesThatUseTransformers(environment.graph);

  var loader = new TransformerLoader(environment, transformerServer);

  // Add a rewrite transformer for each package, so that we can resolve
  // "package:" imports while loading transformers.
  var rewrite = new RewriteImportTransformer();
  for (var package in environment.packages) {
    environment.barback.updateTransformers(package, [[rewrite]]);
  }
  environment.barback.updateTransformers(r'$pub', [[rewrite]]);

  // Only save compiled snapshots when a physical entrypoint package is being
  // used. There's no physical entrypoint when e.g. globally activating a cached
  // package.
  var cache = environment.rootPackage.dir == null ? null :
      environment.graph.loadTransformerCache();

  var first = true;
  for (var stage in stagedTransformers) {
    // Only cache the first stage, since its contents aren't based on other
    // transformers and thus is independent of the current mode.
    var snapshotPath = cache == null || !first ? null :
        cache.snapshotPath(stage);
    first = false;

    /// Load all the transformers in [stage], then add them to the appropriate
    /// locations in the transformer graphs of the packages that use them.
    await loader.load(stage, snapshot: snapshotPath);

    // Only update packages that use transformers in [stage].
    var packagesToUpdate = unionAll(stage.map((id) =>
        packagesThatUseTransformers[id]));
    await Future.wait(packagesToUpdate.map((packageName) async {
      var package = environment.graph.packages[packageName];
      var phases = await loader.transformersForPhases(
          package.pubspec.transformers);

      // Make sure [rewrite] is still the first phase so that future
      // transformers' "package:" imports will work.
      phases.insert(0, new Set.from([rewrite]));
      environment.barback.updateTransformers(packageName, phases);
    }));
  }

  if (cache != null) cache.save();

  /// Reset the transformers for each package to get rid of [rewrite], which
  /// is no longer needed.
  await Future.wait(environment.packages.map((packageName) async {
    var package = environment.graph.packages[packageName];
    var phases = await loader.transformersForPhases(
        package.pubspec.transformers);
    var transformers = environment.getBuiltInTransformers(package);
    if (transformers != null) phases.add(transformers);

    // TODO(nweiz): remove the [newFuture] here when issue 17305 is fixed.
    // If no transformer in [phases] applies to a source input,
    // [updateTransformers] may cause a [BuildResult] to be scheduled for
    // immediate emission. Issue 17305 means that the caller will be unable
    // to receive this result unless we delay the update to after this
    // function returns.
    newFuture(() =>
        environment.barback.updateTransformers(package.name, phases));
  }));
}

/// Given [transformerDependencies], a directed acyclic graph, returns a list of
/// "stages" (sets of transformers).
///
/// Each stage must be fully loaded and passed to barback before the next stage
/// can be safely loaded. However, transformers within a stage can be safely
/// loaded in parallel.
List<Set<TransformerId>> _stageTransformers(
    Map<TransformerId, Set<TransformerId>> transformerDependencies) {
  // A map from transformer ids to the indices of the stages that those
  // transformer ids should end up in. Populated by [stageNumberFor].
  var stageNumbers = {};
  var stages = [];

  stageNumberFor(id) {
    if (stageNumbers.containsKey(id)) return stageNumbers[id];
    var dependencies = transformerDependencies[id];
    stageNumbers[id] = dependencies.isEmpty ? 0 :
        maxAll(dependencies.map(stageNumberFor)) + 1;
    return stageNumbers[id];
  }

  for (var id in transformerDependencies.keys) {
    var stageNumber = stageNumberFor(id);
    if (stages.length <= stageNumber) stages.length = stageNumber + 1;
    if (stages[stageNumber] == null) stages[stageNumber] = new Set();
    stages[stageNumber].add(id);
  }

  return stages;
}

/// Returns a map from transformer ids to all packages in [graph] that use each
/// transformer.
Map<TransformerId, Set<String>> _packagesThatUseTransformers(
    PackageGraph graph) {
  var results = {};
  for (var package in graph.packages.values) {
    for (var phase in package.pubspec.transformers) {
      for (var config in phase) {
        results.putIfAbsent(config.id, () => new Set()).add(package.name);
      }
    }
  }
  return results;
}
