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
  var rewrite = new RewriteImportTransformer();
  for (var package in environment.packages) {
    environment.barback.updateTransformers(package, [[rewrite]]);
  }
  environment.barback.updateTransformers(r'$pub', [[rewrite]]);
  return Future.forEach(phasedTransformers, (phase) {
    return loader.load(phase).then((_) {
      var packagesToUpdate =
          unionAll(phase.map((id) => packagesThatUseTransformers[id]));
      return Future.wait(packagesToUpdate.map((packageName) {
        var package = environment.graph.packages[packageName];
        return loader.transformersForPhases(
            package.pubspec.transformers).then((phases) {
          phases.insert(0, new Set.from([rewrite]));
          environment.barback.updateTransformers(packageName, phases);
        });
      }));
    });
  }).then((_) {
    return Future.wait(environment.graph.packages.values.map((package) {
      return loader.transformersForPhases(
          package.pubspec.transformers).then((phases) {
        var transformers = environment.getBuiltInTransformers(package);
        if (transformers != null) phases.add(transformers);
        newFuture(
            () => environment.barback.updateTransformers(package.name, phases));
      });
    }));
  });
}
List<Set<TransformerId>> _phaseTransformers(Map<TransformerId,
    Set<TransformerId>> transformerDependencies) {
  var phaseNumbers = {};
  var phases = [];
  phaseNumberFor(id) {
    if (phaseNumbers.containsKey(id)) return phaseNumbers[id];
    var dependencies = transformerDependencies[id];
    phaseNumbers[id] =
        dependencies.isEmpty ? 0 : maxAll(dependencies.map(phaseNumberFor)) + 1;
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
Map<TransformerId, Set<String>> _packagesThatUseTransformers(PackageGraph graph)
    {
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
class _TransformerLoader {
  final AssetEnvironment _environment;
  final BarbackServer _transformerServer;
  final _isolates = new Map<TransformerId, TransformerIsolate>();
  final _transformers = new Map<TransformerConfig, Set<Transformer>>();
  final _transformerUsers = new Map<TransformerId, Set<String>>();
  _TransformerLoader(this._environment, this._transformerServer) {
    for (var package in _environment.graph.packages.values) {
      for (var config in unionAll(package.pubspec.transformers)) {
        _transformerUsers.putIfAbsent(
            config.id,
            () => new Set<String>()).add(package.name);
      }
    }
  }
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
          location =
              'package:${config.id.package}/transformer.dart or '
                  'package:${config.id.package}/${config.id.package}.dart';
        } else {
          location = 'package:$config.dart';
        }
        var users = toSentence(ordered(_transformerUsers[config.id]));
        fail("$message were defined in $location,\n" "required by $users.");
      });
    } else if (config.id.package != '\$dart2js') {
      return new Future.value(new Set());
    }
    var transformer;
    try {
      transformer = new Dart2JSTransformer.withSettings(
          _environment,
          new BarbackSettings(config.configuration, _environment.mode));
    } on FormatException catch (error, stackTrace) {
      fail(error.message, error, stackTrace);
    }
    _transformers[config] =
        new Set.from([ExcludingTransformer.wrap(transformer, config)]);
    return new Future.value(_transformers[config]);
  }
  Future<List<Set<Transformer>>>
      transformersForPhases(Iterable<Set<TransformerConfig>> phases) {
    return Future.wait(phases.map((phase) {
      return waitAndPrintErrors(phase.map(transformersFor)).then(unionAll);
    })).then((phases) {
      return phases.toList();
    });
  }
}
