// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.load_all_transformers;

import 'dart:async';

import 'package:barback/barback.dart';

import '../barback.dart';
import '../log.dart' as log;
import '../package_graph.dart';
import '../utils.dart';
import 'asset_environment.dart';
import 'barback_server.dart';
import 'dart2js_transformer.dart';
import 'excluding_transformer.dart';
import 'load_transformers.dart';
import 'rewrite_import_transformer.dart';
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
    BarbackServer transformerServer) {
  var transformersNeededByTransformers =
      computeTransformersNeededByTransformers(environment.graph);

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

  var phasedTransformers = _phaseTransformers(transformersNeededByTransformers);

  var packagesThatUseTransformers =
      _packagesThatUseTransformers(environment.graph);

  var loader = new _TransformerLoader(environment, transformerServer);

  // Add a rewrite transformer for each package, so that we can resolve
  // "package:" imports while loading transformers.
  var rewrite = new RewriteImportTransformer();
  for (var package in environment.graph.packages.values) {
    environment.barback.updateTransformers(package.name, [[rewrite]]);
  }
  environment.barback.updateTransformers(r'$pub', [[rewrite]]);

  return Future.forEach(phasedTransformers, (phase) {
    /// Load all the transformers in [phase], then add them to the appropriate
    /// locations in the transformer graphs of the packages that use them.
    return loader.load(phase).then((_) {
      // Only update packages that use transformers in [phase].
      var packagesToUpdate = unionAll(phase.map((id) =>
          packagesThatUseTransformers[id]));
      for (var packageName in packagesToUpdate) {
        var package = environment.graph.packages[packageName];
        var transformers = package.pubspec.transformers.map((packagePhase) {
          return unionAll(packagePhase.map(loader.transformersFor));
        }).toList();

        // Make sure [rewrite] is still the first phase so that future
        // transformers' "package:" imports will work.
        transformers.insert(0, [rewrite]);
        environment.barback.updateTransformers(packageName, transformers);
      }
    });
  }).then((_) {
    /// Reset the transformers for each package to get rid of [rewrite], which
    /// is no longer needed.
    for (var package in environment.graph.packages.values) {
      var phases = package.pubspec.transformers.map((phase) {
        return unionAll(phase.map((id) => loader.transformersFor(id)));
      }).toList();

      var transformers = environment.getBuiltInTransformers(package);
      if (transformers != null) phases.add(transformers);

      // TODO(nweiz): remove the [newFuture] here when issue 17305 is fixed. If
      // no transformer in [phases] applies to a source input,
      // [updateTransformers] may cause a [BuildResult] to be scheduled for
      // immediate emission. Issue 17305 means that the caller will be unable to
      // receive this result unless we delay the update to after this function
      // returns.
      newFuture(() =>
          environment.barback.updateTransformers(package.name, phases));
    }
  });
}

/// Given [transformerDependencies], a directed acyclic graph, returns a list of
/// "phases" (sets of transformers).
///
/// Each phase must be fully loaded and passed to barback before the next phase
/// can be safely loaded. However, transformers within a phase can be safely
/// loaded in parallel.
List<Set<TransformerId>> _phaseTransformers(
    Map<TransformerId, Set<TransformerId>> transformerDependencies) {
  // A map from transformer ids to the indices of the phases that those
  // transformer ids should end up in. Populated by [phaseNumberFor].
  var phaseNumbers = {};
  var phases = [];

  phaseNumberFor(id) {
    if (phaseNumbers.containsKey(id)) return phaseNumbers[id];
    var dependencies = transformerDependencies[id];
    phaseNumbers[id] = dependencies.isEmpty ? 0 :
        maxAll(dependencies.map(phaseNumberFor)) + 1;
    return phaseNumbers[id];
  }

  for (var id in transformerDependencies.keys) {
    var phaseNumber = phaseNumberFor(id);
    if (phases.length <= phaseNumber) phases.length = phaseNumber + 1;
    if (phases[phaseNumber] == null) phases[phaseNumber] = new Set();
    phases[phaseNumber].add(id);
  }

  return phases;
}

/// Returns a map from transformer ids to all packages in [graph] that use each
/// transformer.
Map<TransformerId, Set<String>> _packagesThatUseTransformers(
    PackageGraph graph) {
  var results = {};
  for (var package in graph.packages.values) {
    for (var phase in package.pubspec.transformers) {
      for (var id in phase) {
        results.putIfAbsent(id, () => new Set()).add(package.name);
      }
    }
  }
  return results;
}

/// A class that loads transformers defined in specific files.
class _TransformerLoader {
  final AssetEnvironment _environment;

  final BarbackServer _transformerServer;

  /// The loaded transformers defined in the library identified by each
  /// transformer id.
  final _transformers = new Map<TransformerId, Set<Transformer>>();

  /// The packages that use each transformer asset id.
  ///
  /// Used for error reporting.
  final _transformerUsers = new Map<Pair<String, String>, Set<String>>();

  // TODO(nweiz): Make this a view when issue 17637 is fixed.
  /// The set of all transformers that have been loaded so far.
  Set<TransformerId> get loadedTransformers => _transformers.keys.toSet();

  _TransformerLoader(this._environment, this._transformerServer) {
    for (var package in _environment.graph.packages.values) {
      for (var id in unionAll(package.pubspec.transformers)) {
        _transformerUsers.putIfAbsent(
            new Pair(id.package, id.path), () => new Set<String>())
            .add(package.name);
      }
    }
  }

  /// Loads the transformer(s) defined in [ids].
  ///
  /// Once the returned future completes, these transformers can be retrieved
  /// using [transformersFor]. If any id doesn't define any transformers, this
  /// will complete to an error.
  ///
  /// This will skip and ids that have already been loaded.
  Future load(Iterable<TransformerId> ids) {
    ids = ids.where((id) => !_transformers.containsKey(id)).toList();
    if (ids.isEmpty) return new Future.value();

    // TODO(nweiz): load multiple instances of the same transformer from the
    // same isolate rather than spinning up a separate isolate for each one.
    return log.progress("Loading ${toSentence(ids)} transformers",
        () => loadTransformers(_environment, _transformerServer, ids))
        .then((allTransformers) {
      for (var id in ids) {
        var transformers = allTransformers[id];
        if (transformers != null && transformers.isNotEmpty) {
          _transformers[id] = transformers;
          continue;
        }

        var message = "No transformers";
        if (id.configuration.isNotEmpty) {
          message += " that accept configuration";
        }

        var location;
        if (id.path == null) {
          location = 'package:${id.package}/transformer.dart or '
            'package:${id.package}/${id.package}.dart';
        } else {
          location = 'package:$id.dart';
        }
        var pair = new Pair(id.package, id.path);

        throw new ApplicationException(
            "$message were defined in $location,\n"
            "required by ${ordered(_transformerUsers[pair]).join(', ')}.");
      }
    });
  }

  /// Returns the set of transformers for [id].
  ///
  /// If this is called before [load] for a given [id], it will return an empty
  /// set.
  Set<Transformer> transformersFor(TransformerId id) {
    if (_transformers.containsKey(id)) return _transformers[id];
    if (id.package != '\$dart2js') return new Set();

    var transformer;
    try {
      transformer = new Dart2JSTransformer.withSettings(_environment,
          new BarbackSettings(id.configuration, _environment.mode));

      // Handle any exclusions.
      transformer = ExcludingTransformer.wrap(transformer, id);
    } on FormatException catch (error, stackTrace) {
      fail(error.message, error, stackTrace);
    }

    _transformers[id] = new Set.from([transformer]);
    return _transformers[id];
  }
}
