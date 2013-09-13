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

/// An identifier for a transformer and the configuration that will be passed to
/// it.
///
/// It's possible that [asset] defines multiple transformers. If so,
/// [configuration] will be passed to all of them.
class TransformerId {
  /// The asset containing the transformer.
  final AssetId asset;

  /// The configuration to pass to the transformer.
  ///
  /// This will be null if no configuration was provided.
  final Map configuration;

  TransformerId(this.asset, this.configuration) {
    if (configuration == null) return;
    for (var reserved in ['include', 'exclude']) {
      if (!configuration.containsKey(reserved)) continue;
      throw new FormatException('Configuration for transformer '
          '${idToLibraryIdentifier(asset)} may not include reserved key '
          '"$reserved".');
    }
  }

  // TODO(nweiz): support deep equality on [configuration] as well.
  bool operator==(other) => other is TransformerId &&
      other.asset == asset &&
      other.configuration == configuration;

  int get hashCode => asset.hashCode ^ configuration.hashCode;
}

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

/// Parses a library identifier to an asset id.
///
/// A library identifier is a string of the form "package_name" or
/// "package_name/path/to/library". It does not have a trailing extension. If it
/// just has a package name, it expands to lib/${package}.dart in that package.
/// Otherwise, it expands to lib/${path}.dart in that package.
AssetId libraryIdentifierToId(String identifier) {
  if (identifier.isEmpty) {
    throw new FormatError('Invalid library identifier: "".');
  }

  // Convert the concise asset name in the pubspec (of the form "package"
  // or "package/library") to an AssetId that points to an actual dart
  // file ("package/lib/package.dart" or "package/lib/library.dart",
  // respectively).
  var parts = split1(identifier, "/");
  if (parts.length == 1) parts.add(parts.single);
  return new AssetId(parts.first, 'lib/' + parts.last + '.dart');
}

final _libraryPathRegExp = new RegExp(r"^lib/(.*)\.dart$");

/// Converts [id] to a library identifier.
///
/// A library identifier is a string of the form "package_name" or
/// "package_name/path/to/library". It does not have a trailing extension. If it
/// just has a package name, it expands to lib/${package}.dart in that package.
/// Otherwise, it expands to lib/${path}.dart in that package.
///
/// This will throw an [ArgumentError] if [id] doesn't represent a library in
/// `lib/`.
String idToLibraryIdentifier(AssetId id) {
  var match = _libraryPathRegExp.firstMatch(id.path);
  if (match == null) {
    throw new ArgumentError("Asset id $id doesn't identify a library.");
  }

  if (match[1] == id.package) return id.package;
  return '${id.package}/${match[1]}';
}

/// Converts [id] to a "package:" URI.
///
/// This will throw an [ArgumentError] if [id] doesn't represent a library in
/// `lib/`.
Uri idToPackageUri(AssetId id) {
  if (!id.path.startsWith('lib/')) {
    throw new ArgumentError("Asset id $id doesn't identify a library.");
  }

  return new Uri(scheme: 'package', path: id.path.replaceFirst('lib/', ''));
}
