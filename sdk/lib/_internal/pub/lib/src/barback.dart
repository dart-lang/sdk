// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback;

import 'dart:async';

import 'package:barback/barback.dart';

import 'barback/load_all_transformers.dart';
import 'barback/pub_package_provider.dart';
import 'barback/rewrite_import_transformer.dart';
import 'barback/server.dart';
import 'barback/watch_sources.dart';
import 'utils.dart';

/// Creates a [BarbackServer] serving on [host] and [port].
///
/// This transforms and serves all library and asset files in all packages in
/// [graph]. It loads any transformer plugins defined in packages in [graph] and
/// re-runs them as necessary when any input files change.
Future<BarbackServer> createServer(String host, int port, PackageGraph graph) {
  var provider = new PubPackageProvider(graph);
  var barback = new Barback(provider);
  return BarbackServer.bind(host, port, barback, graph.entrypoint.root.name)
      .then((server) {
    watchSources(graph, barback);

    var completer = new Completer();

    // If any errors get emitted either by barback or by the server, including
    // non-programmatic barback errors, they should take down the whole program.
    var subscriptions = [
      server.barback.errors.listen((error) {
        if (error is TransformerException) error = error.error;
        if (!completer.isCompleted) completer.completeError(error);
      }),
      server.barback.results.listen((_) {}, onError: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      }),
      server.results.listen((_) {}, onError: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      })
    ];

    loadAllTransformers(server, graph).then((_) {
      if (!completer.isCompleted) completer.complete(server);
    }).catchError((error) {
      if (!completer.isCompleted) completer.completeError(error);
    });

    return completer.future.whenComplete(() {
      for (var subscription in subscriptions) {
        subscription.cancel();
      }
    });
  });
}
