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
Future loadAllTransformers(AssetEnvironment environment,
    BarbackServer transformerServer) {
  final completer0 = new Completer();
  scheduleMicrotask(() {
    try {
      var transformersNeededByTransformers =
          computeTransformersNeededByTransformers(
              environment.graph,
              packages: environment.packages);
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
      var rewrite = new RewriteImportTransformer();
      var it0 = environment.packages.iterator;
      break0(x9) {
        environment.barback.updateTransformers(r'$pub', [[rewrite]]);
        join0(x0) {
          var cache = x0;
          var first = true;
          var it1 = stagedTransformers.iterator;
          break1(x6) {
            join1() {
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
                          newFuture(
                              (() => environment.barback.updateTransformers(package.name, phases)));
                          completer0.complete(null);
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
              join1();
            } else {
              join1();
            }
          }
          continue1(x7) {
            if (it1.moveNext()) {
              Future.wait([]).then((x5) {
                var stage = it1.current;
                join2(x2) {
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
                                phases.insert(0, new Set.from([rewrite]));
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
                          continue1(null);
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
                  join2(null);
                } else {
                  join2(cache.snapshotPath(stage));
                }
              });
            } else {
              break1(null);
            }
          }
          continue1(null);
        }
        if (environment.rootPackage.dir == null) {
          join0(null);
        } else {
          join0(environment.graph.loadTransformerCache());
        }
      }
      continue0(x10) {
        if (it0.moveNext()) {
          Future.wait([]).then((x8) {
            var package = it0.current;
            environment.barback.updateTransformers(package, [[rewrite]]);
            continue0(null);
          });
        } else {
          break0(null);
        }
      }
      continue0(null);
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
