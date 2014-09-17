library pub.barback.transformer_loader;
import 'dart:async';
import 'package:barback/barback.dart';
import '../log.dart' as log;
import '../utils.dart';
import 'asset_environment.dart';
import 'barback_server.dart';
import 'dart2js_transformer.dart';
import 'excluding_transformer.dart';
import 'transformer_config.dart';
import 'transformer_id.dart';
import 'transformer_isolate.dart';
class TransformerLoader {
  final AssetEnvironment _environment;
  final BarbackServer _transformerServer;
  final _isolates = new Map<TransformerId, TransformerIsolate>();
  final _transformers = new Map<TransformerConfig, Set<Transformer>>();
  final _transformerUsers = new Map<TransformerId, Set<String>>();
  TransformerLoader(this._environment, this._transformerServer) {
    for (var package in _environment.graph.packages.values) {
      for (var config in unionAll(package.pubspec.transformers)) {
        _transformerUsers.putIfAbsent(
            config.id,
            () => new Set<String>()).add(package.name);
      }
    }
  }
  Future load(Iterable<TransformerId> ids, {String snapshot}) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        ids = ids.where(((id) => !_isolates.containsKey(id))).toList();
        join0() {
          log.progress(
              "Loading ${toSentence(ids)} transformers",
              (() =>
                  TransformerIsolate.spawn(
                      _environment,
                      _transformerServer,
                      ids,
                      snapshot: snapshot))).then((x0) {
            try {
              var isolate = x0;
              var it0 = ids.iterator;
              break0(x2) {
                completer0.complete(null);
              }
              continue0(x3) {
                if (it0.moveNext()) {
                  Future.wait([]).then((x1) {
                    var id = it0.current;
                    _isolates[id] = isolate;
                    continue0(null);
                  });
                } else {
                  break0(null);
                }
              }
              continue0(null);
            } catch (e0) {
              completer0.completeError(e0);
            }
          }, onError: (e1) {
            completer0.completeError(e1);
          });
        }
        if (ids.isEmpty) {
          completer0.complete(null);
        } else {
          join0();
        }
      } catch (e2) {
        completer0.completeError(e2);
      }
    });
    return completer0.future;
  }
  Future<Set<Transformer>> transformersFor(TransformerConfig config) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        join0() {
          join1() {
            var transformer = (() {
              try {
                return new Dart2JSTransformer.withSettings(
                    _environment,
                    new BarbackSettings(config.configuration, _environment.mode));
              } on FormatException catch (error, stackTrace) {
                fail(error.message, error, stackTrace);
              }
            })();
            _transformers[config] =
                new Set.from([ExcludingTransformer.wrap(transformer, config)]);
            completer0.complete(_transformers[config]);
          }
          if (_isolates.containsKey(config.id)) {
            _isolates[config.id].create(config).then((x0) {
              try {
                var transformers = x0;
                join2() {
                  var message = "No transformers";
                  join3() {
                    var location;
                    join4() {
                      var users =
                          toSentence(ordered(_transformerUsers[config.id]));
                      fail(
                          "${message} were defined in ${location},\n" "required by ${users}.");
                      join1();
                    }
                    if (config.id.path == null) {
                      location =
                          'package:${config.id.package}/transformer.dart or '
                              'package:${config.id.package}/${config.id.package}.dart';
                      join4();
                    } else {
                      location = 'package:${config}.dart';
                      join4();
                    }
                  }
                  if (config.configuration.isNotEmpty) {
                    message += " that accept configuration";
                    join3();
                  } else {
                    join3();
                  }
                }
                if (transformers.isNotEmpty) {
                  _transformers[config] = transformers;
                  completer0.complete(transformers);
                } else {
                  join2();
                }
              } catch (e0) {
                completer0.completeError(e0);
              }
            }, onError: (e1) {
              completer0.completeError(e1);
            });
          } else {
            join5() {
              join1();
            }
            if (config.id.package != '\$dart2js') {
              completer0.complete(new Future.value(new Set()));
            } else {
              join5();
            }
          }
        }
        if (_transformers.containsKey(config)) {
          completer0.complete(_transformers[config]);
        } else {
          join0();
        }
      } catch (e2) {
        completer0.completeError(e2);
      }
    });
    return completer0.future;
  }
  Future<List<Set<Transformer>>>
      transformersForPhases(Iterable<Set<TransformerConfig>> phases) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        Future.wait(phases.map(((phase) {
          final completer0 = new Completer();
          scheduleMicrotask(() {
            try {
              waitAndPrintErrors(phase.map(transformersFor)).then((x0) {
                try {
                  var transformers = x0;
                  completer0.complete(unionAll(transformers));
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
        }))).then((x0) {
          try {
            var result = x0;
            completer0.complete(result.toList());
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
  }
}
