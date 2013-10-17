// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import 'barback/load_all_transformers.dart';
import 'barback/pub_barback_logger.dart';
import 'barback/pub_package_provider.dart';
import 'barback/server.dart';
import 'barback/watch_sources.dart';
import 'package_graph.dart';
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
      throw new FormatException('Transformer configuration may not include '
          'reserved key "$reserved".');
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
///
/// If [builtInTransformers] is provided, then a phase is added to the end of
/// each package's cascade including those transformers.
Future<BarbackServer> createServer(String host, int port, PackageGraph graph,
    {Iterable<Transformer> builtInTransformers}) {
  var provider = new PubPackageProvider(graph);
  var logger = new PubBarbackLogger();
  var barback = new Barback(provider, logger: logger);

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
      server.barback.results.listen((_) {}, onError: (error, stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      }),
      server.results.listen((_) {}, onError: (error, stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      })
    ];

    loadAllTransformers(server, graph, builtInTransformers).then((_) {
      if (!completer.isCompleted) completer.complete(server);
    }).catchError((error, stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
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
    throw new FormatException('Invalid library identifier: "".');
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

/// Converts [uri] into an [AssetId] if it has a path containing "packages" or
/// "assets".
///
/// If the URI doesn't contain one of those special directories, returns null.
/// If it does contain a special directory, but lacks a following package name,
/// throws a [FormatException].
AssetId specialUrlToId(Uri url) {
  var parts = path.url.split(url.path);

  for (var pair in [["packages", "lib"], ["assets", "asset"]]) {
    var partName = pair.first;
    var dirName = pair.last;

    // Find the package name and the relative path in the package.
    var index = parts.indexOf(partName);
    if (index == -1) continue;

    // If we got here, the path *did* contain the special directory, which
    // means we should not interpret it as a regular path. If it's missing the
    // package name after the special directory, it's invalid.
    if (index + 1 >= parts.length) {
      throw new FormatException(
          'Invalid package path "${path.url.joinAll(parts)}". '
          'Expected package name after "$partName".');
    }

    var package = parts[index + 1];
    var assetPath = path.url.join(dirName,
        path.url.joinAll(parts.skip(index + 2)));
    return new AssetId(package, assetPath);
  }

  return null;
}

/// Converts [id] to a "servable path" for that asset.
///
/// This is the root relative URL that could be used to request that asset from
/// pub serve. It's also the relative path that the asset will be output to by
/// pub build (except this always returns a path using URL separators).
///
/// [entrypoint] is the name of the entrypoint package.
///
/// Examples (where [entrypoint] is "myapp"):
///
///     myapp|web/index.html   -> /index.html
///     myapp|lib/lib.dart     -> /packages/myapp/lib.dart
///     foo|lib/foo.dart       -> /packages/foo/foo.dart
///     foo|asset/foo.png      -> /assets/foo/foo.png
///     myapp|test/main.dart   -> ERROR
///     foo|web/
///
/// Throws a [FormatException] if [id] is not a valid public asset.
String idtoUrlPath(String entrypoint, AssetId id) {
  var parts = path.url.split(id.path);

  if (parts.length < 2) {
    throw new FormatException(
        "Can not serve assets from top-level directory.");
  }

  // Each top-level directory gets handled differently.
  var dir = parts[0];
  parts = parts.skip(1);

  switch (dir) {
    case "asset":
      return path.url.join("/", "assets", id.package, path.url.joinAll(parts));

    case "lib":
      return path.url.join("/", "packages", id.package, path.url.joinAll(parts));

    case "web":
      if (id.package != entrypoint) {
        throw new FormatException(
            'Cannot access "web" directory of non-root packages.');
      }
      return path.url.join("/", path.url.joinAll(parts));

    default:
      throw new FormatException('Cannot access assets from "$dir".');
  }
}
