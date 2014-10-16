// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

/// A class that loads transformers defined in specific files.
class TransformerLoader {
  final AssetEnvironment _environment;

  final BarbackServer _transformerServer;

  final _isolates = new Map<TransformerId, TransformerIsolate>();

  final _transformers = new Map<TransformerConfig, Set<Transformer>>();

  /// The packages that use each transformer id.
  ///
  /// Used for error reporting.
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

  /// Loads a transformer plugin isolate that imports the transformer libraries
  /// indicated by [ids].
  ///
  /// Once the returned future completes, transformer instances from this
  /// isolate can be created using [transformersFor] or [transformersForPhase].
  ///
  /// This skips any ids that have already been loaded.
  Future load(Iterable<TransformerId> ids, {String snapshot}) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        ids = ids.where(((id) {
          return !_isolates.containsKey(id);
        })).toList();
        join0() {
          log.progress("Loading ${toSentence(ids)} transformers", (() {
            return TransformerIsolate.spawn(
                _environment,
                _transformerServer,
                ids,
                snapshot: snapshot);
          })).then((x0) {
            try {
              var isolate = x0;
              var it0 = ids.iterator;
              break0() {
                completer0.complete();
              }
              var trampoline0;
              continue0() {
                trampoline0 = null;
                if (it0.moveNext()) {
                  var id = it0.current;
                  _isolates[id] = isolate;
                  trampoline0 = continue0;
                } else {
                  break0();
                }
              }
              trampoline0 = continue0;
              do trampoline0(); while (trampoline0 != null);
            } catch (e0, s0) {
              completer0.completeError(e0, s0);
            }
          }, onError: completer0.completeError);
        }
        if (ids.isEmpty) {
          completer0.complete(null);
        } else {
          join0();
        }
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }

  /// Instantiates and returns all transformers in the library indicated by
  /// [config] with the given configuration.
  ///
  /// If this is called before the library has been loaded into an isolate via
  /// [load], it will return an empty set.
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
              } catch (e0, s0) {
                completer0.completeError(e0, s0);
              }
            }, onError: completer0.completeError);
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
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }

  /// Loads all transformers defined in each phase of [phases].
  ///
  /// If any library hasn't yet been loaded via [load], it will be ignored.
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
                } catch (e0, s0) {
                  completer0.completeError(e0, s0);
                }
              }, onError: completer0.completeError);
            } catch (e, s) {
              completer0.completeError(e, s);
            }
          });
          return completer0.future;
        }))).then((x0) {
          try {
            var result = x0;
            completer0.complete(result.toList());
          } catch (e0, s0) {
            completer0.completeError(e0, s0);
          }
        }, onError: completer0.completeError);
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }
}
