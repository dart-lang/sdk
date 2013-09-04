// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback;

import 'dart:async';

import 'package:barback/barback.dart';

import 'barback/load_transformers.dart';
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

    _loadTransformers(server, graph).then((_) {
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

/// Loads all transformers depended on by packages in [graph].
///
/// This uses [server] to serve the Dart files from which transformers are
/// loaded, then adds the transformers to `server.barback`.
Future _loadTransformers(BarbackServer server, PackageGraph graph) {
  // Add a rewrite transformer for each package, so that we can resolve
  // "package:" imports while loading transformers.
  var rewrite = new RewriteImportTransformer();
  for (var package in graph.packages.values) {
    server.barback.updateTransformers(package.name, [[rewrite]]);
  }

  // A map from each transformer id to the set of packages that use it.
  var idsToPackages = new Map<AssetId, Set<String>>();
  for (var package in graph.packages.values) {
    for (var id in unionAll(package.pubspec.transformers)) {
      idsToPackages.putIfAbsent(id, () => new Set<String>()).add(package.name);
    }
  }

  // TODO(nweiz): support transformers that (possibly transitively)
  // depend on other transformers.
  var transformersForId = new Map<AssetId, Set<Transformer>>();
  return Future.wait(idsToPackages.keys.map((id) {
    return loadTransformers(server, id).then((transformers) {
      if (transformers.isEmpty) {
        var path = id.path.replaceFirst('lib/', '');
        // Ensure that packages are listed in a deterministic order.
        var packages = idsToPackages[id].toList();
        packages.sort();
        throw new ApplicationException(
            "No transformers were defined in package:${id.package}/$path,\n"
            "required by ${packages.join(', ')}.");
      }

      transformersForId[id] = transformers;
    });
  })).then((_) {
    for (var package in graph.packages.values) {
      var phases = package.pubspec.transformers.map((phase) {
        return unionAll(phase.map((id) => transformersForId[id]));
      });
      server.barback.updateTransformers(package.name, phases);
    }
  });
}
