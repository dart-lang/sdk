// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.load_all_transformers;

import 'dart:async';

import 'package:barback/barback.dart';

import 'load_transformers.dart';
import 'rewrite_import_transformer.dart';
import 'server.dart';
import 'watch_sources.dart';
import '../barback.dart';
import '../utils.dart';

/// Loads all transformers depended on by packages in [graph].
///
/// This uses [server] to serve the Dart files from which transformers are
/// loaded, then adds the transformers to `server.barback`.
Future loadAllTransformers(BarbackServer server, PackageGraph graph) {
  // In order to determine in what order we should load transformers, we need to
  // know which transformers depend on which others. This is different than
  // normal package dependencies. Let's begin with some terminology:
  //
  // * If package A is transformed by package B, we say A has a "transformer
  //   dependency" on B.
  // * If A imports B we say A has a "package dependency" on B.
  // * If A needs B's transformers to be loaded in order to load A's
  //   transformers, we say A has an "ordering dependency" on B.
  //
  // In particular, an ordering dependency is defined as follows:
  //
  // * If A has a transformer dependency on B, A also has an ordering dependency
  //   on B.
  // * If A has a transitive package dependency on B and B has a transformer
  //   dependency on C, A has an ordering dependency on C.
  //
  // The order that transformers are loaded is determined by each package's
  // ordering dependencies. We treat the packages as a directed acyclic[1] graph
  // where each package is a node and the ordering dependencies are the edges
  // (that is, the packages form a partially ordered set). We then load[2]
  // packages in a topological sort order of this graph.
  //
  // [1] TODO(nweiz): support cycles in some cases.
  //
  // [2] We use "loading a package" as a shorthand for loading that package's
  //     transformers.

  // Add a rewrite transformer for each package, so that we can resolve
  // "package:" imports while loading transformers.
  var rewrite = new RewriteImportTransformer();
  for (var package in graph.packages.values) {
    server.barback.updateTransformers(package.name, [[rewrite]]);
  }

  var orderingDeps = _computeOrderingDeps(graph);
  var packageTransformers = _computePackageTransformers(graph);

  var loader = new _TransformerLoader(server, graph);

  // The packages on which no packages have ordering dependencies -- that is,
  // the packages that don't need to be loaded before any other packages. These
  // packages will be loaded last, since all of their ordering dependencies need
  // to be loaded before they're loaded. However, they'll be traversed by
  // [loadPackage] first.
  var rootPackages = graph.packages.keys.toSet()
      .difference(unionAll(orderingDeps.values));

  // The Futures for packages that have been loaded or are being actively loaded
  // by [loadPackage]. Once one of these Futures is complete, the transformers
  // for that package will all be available from [loader].
  var loadingPackages = new Map<String, Future>();

  // A helper function that loads all the transformers that [package] uses, then
  // all the transformers that [package] defines.
  Future loadPackage(String package) {
    if (loadingPackages.containsKey(package)) return loadingPackages[package];

    // First, load each package upon which [package] has an ordering dependency.
    var future = Future.wait(orderingDeps[package].map(loadPackage)).then((_) {
      // Go through the transformers used by [package] phase-by-phase. If any
      // phase uses a transformer defined in [package] itself, that transform
      // should be loaded after running all previous phases.
      var transformers = [[rewrite]];
      return Future.forEach(graph.packages[package].pubspec.transformers,
          (phase) {
        return Future.wait(phase.where((id) => id.package == package)
            .map(loader.load)).then((_) {
          transformers.add(unionAll(phase.map(
              (id) => loader.transformersFor(id))));
          server.barback.updateTransformers(package, transformers);
        });
      }).then((_) {
        // Now that we've applied all the transformers used by [package] via
        // [Barback.updateTransformers], we load any transformers defined in
        // [package] but used elsewhere.
        return Future.wait(packageTransformers[package].map(loader.load));
      });
    });
    loadingPackages[package] = future;
    return future;
  }

  return Future.wait(rootPackages.map(loadPackage)).then((_) {
    /// Reset the transformers for each package to get rid of [rewrite], which
    /// is no longer needed.
    for (var package in graph.packages.values) {
      var phases = package.pubspec.transformers.map((phase) {
        return unionAll(phase.map((id) => loader.transformersFor(id)));
      });
      server.barback.updateTransformers(package.name, phases);
    }
  });
}

/// Computes and returns the graph of ordering dependencies for [graph].
///
/// This graph is in the form of a map whose keys are packages and whose values
/// are those packages' ordering dependencies.
Map<String, Set<String>> _computeOrderingDeps(PackageGraph graph) {
  var orderingDeps = new Map<String, Set<String>>();
  // Iterate through the packages in a deterministic order so that if there are
  // multiple cycles we choose which to print consistently.
  var packages = ordered(graph.packages.values.map((package) => package.name));
  for (var package in packages) {
    // This package's transformer dependencies are also ordering dependencies.
    var deps = _transformerDeps(graph, package);
    deps.remove(package);
    // The transformer dependencies of this package's transitive package
    // dependencies are also ordering dependencies for this package.
    var transitivePackageDeps = graph.transitiveDependencies(package)
        .map((package) => package.name);
    for (var packageDep in ordered(transitivePackageDeps)) {
      var transformerDeps = _transformerDeps(graph, packageDep);
      if (transformerDeps.contains(package)) {
        throw _cycleError(graph, package, packageDep);
      }
      deps.addAll(transformerDeps);
    }
    orderingDeps[package] = deps;
  }

  return orderingDeps;
}

/// Returns the set of transformer dependencies for [package].
Set<String> _transformerDeps(PackageGraph graph, String package) =>
  unionAll(graph.packages[package].pubspec.transformers)
      .map((id) => id.package).toSet();

/// Returns an [ApplicationException] describing an ordering dependency cycle
/// detected in [graph].
///
/// [dependee] and [depender] should be the names of two packages known to be in
/// the cycle. In addition, [depender] should have a transformer dependency on
/// [dependee].
ApplicationException _cycleError(PackageGraph graph, String dependee,
    String depender) {
  assert(_transformerDeps(graph, depender).contains(dependee));

  var simpleGraph = mapMapValues(graph.packages,
      (_, package) => package.dependencies.map((dep) => dep.name).toList());
  var path = shortestPath(simpleGraph, dependee, depender);
  path.add(dependee);
  return new ApplicationException("Transformer cycle detected:\n" +
      pairs(path).map((pair) {
    var transformers = unionAll(graph.packages[pair.first].pubspec.transformers)
        .where((id) => id.package == pair.last)
        .map(idToLibraryIdentifier).toList();
    if (transformers.isEmpty) {
      return "  ${pair.first} depends on ${pair.last}";
    } else {
      return "  ${pair.first} is transformed by ${toSentence(transformers)}";
    }
  }).join("\n"));
}

/// Returns a map from each package name in [graph] to the asset ids of all
/// transformers exposed by that package and used by other packages.
Map<String, Set<AssetId>> _computePackageTransformers(PackageGraph graph) {
  var packageTransformers = listToMap(graph.packages.values,
      (package) => package.name, (_) => new Set<AssetId>());
  for (var package in graph.packages.values) {
    for (var phase in package.pubspec.transformers) {
      for (var id in phase) {
        packageTransformers[id.package].add(id);
      }
    }
  }
  return packageTransformers;
}

/// A class that loads transformers defined in specific files.
class _TransformerLoader {
  final BarbackServer _server;

  /// The loaded transformers defined in the library identified by each asset
  /// id.
  final _transformers = new Map<AssetId, Set<Transformer>>();

  /// The packages that use each transformer id.
  ///
  /// Used for error reporting.
  final _transformerUsers = new Map<AssetId, Set<String>>();

  _TransformerLoader(this._server, PackageGraph graph) {
    for (var package in graph.packages.values) {
      for (var id in unionAll(package.pubspec.transformers)) {
        _transformerUsers.putIfAbsent(id, () => new Set<String>())
            .add(package.name);
      }
    }
  }

  /// Loads the transformer(s) defined in the asset [id].
  ///
  /// Once the returned future completes, these transformers can be retrieved
  /// using [transformersFor]. If [id] doesn't define any transformers, this
  /// will complete to an error.
  Future load(AssetId id) {
    if (_transformers.containsKey(id)) return new Future.value();

    return loadTransformers(_server, id).then((transformers) {
      if (!transformers.isEmpty) {
        _transformers[id] = transformers;
        return;
      }

      throw new ApplicationException(
          "No transformers were defined in ${idToPackageUri(id)},\n"
          "required by ${ordered(_transformerUsers[id]).join(', ')}.");
    });
  }

  /// Returns the set of transformers for [id].
  ///
  /// It's an error to call this before [load] is called with [id] and the
  /// future it returns has completed.
  Set<Transformers> transformersFor(AssetId id) {
    assert(_transformers.containsKey(id));
    return _transformers[id];
  }
}