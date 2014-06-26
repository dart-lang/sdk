// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.load_all_transformers;

import 'dart:async';

import 'package:barback/barback.dart';

import '../log.dart' as log;
import '../package_graph.dart';
import '../utils.dart';
import 'asset_environment.dart';
import 'barback_server.dart';
import 'dart2js_transformer.dart';
import 'excluding_transformer.dart';
import 'rewrite_import_transformer.dart';
import 'transformer_config.dart';
import 'transformer_id.dart';
import 'transformer_isolate.dart';
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
      return Future.wait(packagesToUpdate.map((packageName) {
        var package = environment.graph.packages[packageName];
        return loader.transformersForPhases(package.pubspec.transformers)
            .then((phases) {

          // Make sure [rewrite] is still the first phase so that future
          // transformers' "package:" imports will work.
          phases.insert(0, new Set.from([rewrite]));
          environment.barback.updateTransformers(packageName, phases);
        });
      }));
    });
  }).then((_) {
    /// Reset the transformers for each package to get rid of [rewrite], which
    /// is no longer needed.
    return Future.wait(environment.graph.packages.values.map((package) {
      return loader.transformersForPhases(package.pubspec.transformers)
          .then((phases) {
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
      });
    }));
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
      for (var config in phase) {
        results.putIfAbsent(config.id, () => new Set()).add(package.name);
      }
    }
  }
  return results;
}

/// A class that loads transformers defined in specific files.
class _TransformerLoader {
  final AssetEnvironment _environment;

  final BarbackServer _transformerServer;

  final _isolates = new Map<TransformerId, TransformerIsolate>();

  final _transformers = new Map<TransformerConfig, Set<Transformer>>();

  /// The packages that use each transformer id.
  ///
  /// Used for error reporting.
  final _transformerUsers = new Map<TransformerId, Set<String>>();

  _TransformerLoader(this._environment, this._transformerServer) {
    for (var package in _environment.graph.packages.values) {
      for (var config in unionAll(package.pubspec.transformers)) {
        _transformerUsers.putIfAbsent(config.id, () => new Set<String>())
            .add(package.name);
      }
    }
  }

  /// Loads a transformer plugin isolate that imports the transformer libraries
  /// indicated by [ids].
  ///
  /// Once the returned future completes, transformer instances from this
  /// isolate can be created using [transformersFor] or [transformersForPhase].
  ///
  /// This will skip any ids that have already been loaded.
  Future load(Iterable<TransformerId> ids) {
    ids = ids.where((id) => !_isolates.containsKey(id)).toList();
    if (ids.isEmpty) return new Future.value();

    return log.progress("Loading ${toSentence(ids)} transformers", () {
      return TransformerIsolate.spawn(_environment, _transformerServer, ids);
    }).then((isolate) {
      for (var id in ids) {
        _isolates[id] = isolate;
      }
    });
  }

  /// Instantiates and returns all transformers in the library indicated by
  /// [config] with the given configuration.
  ///
  /// If this is called before the library has been loaded into an isolate via
  /// [load], it will return an empty set.
  Future<Set<Transformer>> transformersFor(TransformerConfig config) {
    if (_transformers.containsKey(config)) {
      return new Future.value(_transformers[config]);
    } else if (_isolates.containsKey(config.id)) {
      return _isolates[config.id].create(config).then((transformers) {
        if (transformers.isNotEmpty) {
          _transformers[config] = transformers;
          return transformers;
        }

        var message = "No transformers";
        if (config.configuration.isNotEmpty) {
          message += " that accept configuration";
        }

        var location;
        if (config.id.path == null) {
          location = 'package:${config.id.package}/transformer.dart or '
            'package:${config.id.package}/${config.id.package}.dart';
        } else {
          location = 'package:$config.dart';
        }

        var users = toSentence(ordered(_transformerUsers[config.id]));
        fail("$message were defined in $location,\n"
            "required by $users.");
      });
    } else if (config.id.package != '\$dart2js') {
      return new Future.value(new Set());
    }

    var transformer;
    try {
      transformer = new Dart2JSTransformer.withSettings(_environment,
          new BarbackSettings(config.configuration, _environment.mode));
    } on FormatException catch (error, stackTrace) {
      fail(error.message, error, stackTrace);
    }

    // Handle any exclusions.
    _transformers[config] = new Set.from(
        [ExcludingTransformer.wrap(transformer, config)]);
    return new Future.value(_transformers[config]);
  }

  /// Loads all transformers defined in each phase of [phases].
  ///
  /// If any library hasn't yet been loaded via [load], it will be ignored.
  Future<List<Set<Transformer>>> transformersForPhases(
      Iterable<Set<TransformerConfig>> phases) {
    return Future.wait(phases.map((phase) =>
            Future.wait(phase.map(transformersFor)).then(unionAll)))
        // Return a growable list so that callers can add phases.
        .then((phases) => phases.toList());
  }
}
