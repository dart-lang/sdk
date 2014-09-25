library pub.load_all_transformers;
import 'dart:async';
import 'package:barback/barback.dart';
import '../log.dart' as log;
import '../package_graph.dart';
import '../utils.dart';
import 'asset_environment.dart';
import 'barback_server.dart';
import 'dependency_computer.dart';
import 'transformer_id.dart';
import 'transformer_loader.dart';
Future loadAllTransformers(AssetEnvironment environment,
    BarbackServer transformerServer, {Iterable<AssetId> entrypoints}) {
  final completer0 = new Completer();
  scheduleMicrotask(() {
    try {
      var dependencyComputer = new DependencyComputer(environment.graph);
      var necessaryTransformers;
      join0() {
        var transformersNeededByTransformers =
            dependencyComputer.transformersNeededByTransformers(necessaryTransformers);
        var buffer = new StringBuffer();
        buffer.writeln("Transformer dependencies:");
        transformersNeededByTransformers.forEach(((id, dependencies) {
          if (dependencies.isEmpty) {
            buffer.writeln("$id: -");
          } else {
            buffer.writeln("$id: ${toSentence(dependencies)}");
          }
        }));
        log.fine(buffer);
        var stagedTransformers =
            _stageTransformers(transformersNeededByTransformers);
        var packagesThatUseTransformers =
            _packagesThatUseTransformers(environment.graph);
        var loader = new TransformerLoader(environment, transformerServer);
        join1(x0) {
          var cache = x0;
          var first = true;
          var it0 = stagedTransformers.iterator;
          break0(x6) {
            join2() {
              Future.wait(environment.graph.packages.values.map(((package) {
                final completer0 = new Completer();
                scheduleMicrotask(() {
                  try {
                    loader.transformersForPhases(
                        package.pubspec.transformers).then((x0) {
                      try {
                        var phases = x0;
                        var transformers =
                            environment.getBuiltInTransformers(package);
                        join0() {
                          join1() {
                            newFuture(
                                (() => environment.barback.updateTransformers(package.name, phases)));
                            completer0.complete(null);
                          }
                          if (phases.isEmpty) {
                            completer0.complete(null);
                          } else {
                            join1();
                          }
                        }
                        if (transformers != null) {
                          phases.add(transformers);
                          join0();
                        } else {
                          join0();
                        }
                      } catch (e0) {
                        completer0.completeError(e0);
                      }
                    }, onError: (e1) {
                      completer0.completeError(e1);
                    });
                  } catch (e2) {
                    completer0.completeError(e2);
                  }
                });
                return completer0.future;
              }))).then((x1) {
                try {
                  x1;
                  completer0.complete(null);
                } catch (e0) {
                  completer0.completeError(e0);
                }
              }, onError: (e1) {
                completer0.completeError(e1);
              });
            }
            if (cache != null) {
              cache.save();
              join2();
            } else {
              join2();
            }
          }
          continue0(x7) {
            if (it0.moveNext()) {
              Future.wait([]).then((x5) {
                var stage = it0.current;
                join3(x2) {
                  var snapshotPath = x2;
                  first = false;
                  loader.load(stage, snapshot: snapshotPath).then((x3) {
                    try {
                      x3;
                      var packagesToUpdate =
                          unionAll(stage.map(((id) => packagesThatUseTransformers[id])));
                      Future.wait(packagesToUpdate.map(((packageName) {
                        final completer0 = new Completer();
                        scheduleMicrotask(() {
                          try {
                            var package =
                                environment.graph.packages[packageName];
                            loader.transformersForPhases(
                                package.pubspec.transformers).then((x0) {
                              try {
                                var phases = x0;
                                environment.barback.updateTransformers(
                                    packageName,
                                    phases);
                                completer0.complete(null);
                              } catch (e0) {
                                completer0.completeError(e0);
                              }
                            }, onError: (e1) {
                              completer0.completeError(e1);
                            });
                          } catch (e2) {
                            completer0.completeError(e2);
                          }
                        });
                        return completer0.future;
                      }))).then((x4) {
                        try {
                          x4;
                          continue0(null);
                        } catch (e3) {
                          completer0.completeError(e3);
                        }
                      }, onError: (e4) {
                        completer0.completeError(e4);
                      });
                    } catch (e2) {
                      completer0.completeError(e2);
                    }
                  }, onError: (e5) {
                    completer0.completeError(e5);
                  });
                }
                if (cache == null || !first) {
                  join3(null);
                } else {
                  join3(cache.snapshotPath(stage));
                }
              });
            } else {
              break0(null);
            }
          }
          continue0(null);
        }
        if (environment.rootPackage.dir == null) {
          join1(null);
        } else {
          join1(environment.graph.loadTransformerCache());
        }
      }
      if (entrypoints != null) {
        join4() {
          necessaryTransformers =
              unionAll(entrypoints.map(dependencyComputer.transformersNeededByLibrary));
          join5() {
            join0();
          }
          if (necessaryTransformers.isEmpty) {
            log.fine(
                "No transformers are needed for ${toSentence(entrypoints)}.");
            completer0.complete(null);
          } else {
            join5();
          }
        }
        if (entrypoints.isEmpty) {
          completer0.complete(null);
        } else {
          join4();
        }
      } else {
        join0();
      }
    } catch (e6) {
      completer0.completeError(e6);
    }
  });
  return completer0.future;
}
List<Set<TransformerId>> _stageTransformers(Map<TransformerId,
    Set<TransformerId>> transformerDependencies) {
  var stageNumbers = {};
  var stages = [];
  stageNumberFor(id) {
    if (stageNumbers.containsKey(id)) return stageNumbers[id];
    var dependencies = transformerDependencies[id];
    stageNumbers[id] =
        dependencies.isEmpty ? 0 : maxAll(dependencies.map(stageNumberFor)) + 1;
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
