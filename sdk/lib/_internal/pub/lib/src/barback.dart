// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import 'barback/load_all_transformers.dart';
import 'barback/pub_package_provider.dart';
import 'barback/server.dart';
import 'barback/sources.dart';
import 'log.dart' as log;
import 'package_graph.dart';
import 'utils.dart';

/// An identifier for a transformer and the configuration that will be passed to
/// it.
///
/// It's possible that the library identified by [this] defines multiple
/// transformers. If so, [configuration] will be passed to all of them.
class TransformerId {
  /// The package containing the library that this transformer identifies.
  final String package;

  /// The `/`-separated path identifying the library that contains this
  /// transformer.
  ///
  /// This is relative to the `lib/` directory in [package], and doesn't end in
  /// `.dart`.
  ///
  /// This can be null; if so, it indicates that the transformer(s) should be
  /// loaded from `lib/transformer.dart` if that exists, and `lib/$package.dart`
  /// otherwise.
  final String path;

  /// The configuration to pass to the transformer.
  ///
  /// This will be null if no configuration was provided.
  final Map configuration;

  /// Parses a transformer identifier.
  ///
  /// A transformer identifier is a string of the form "package_name" or
  /// "package_name/path/to/library". It does not have a trailing extension. If
  /// it just has a package name, it expands to lib/transformer.dart if that
  /// exists, or lib/${package}.dart otherwise. Otherwise, it expands to
  /// lib/${path}.dart. In either case it's located in the given package.
  factory TransformerId.parse(String identifier, Map configuration) {
    if (identifier.isEmpty) {
      throw new FormatException('Invalid library identifier: "".');
    }

    var parts = split1(identifier, "/");
    if (parts.length == 1) {
      return new TransformerId(parts.single, null, configuration);
    }
    return new TransformerId(parts.first, parts.last, configuration);
  }

  TransformerId(this.package, this.path, this.configuration) {
    if (configuration == null) return;
    for (var reserved in ['include', 'exclude']) {
      if (!configuration.containsKey(reserved)) continue;
      throw new FormatException('Transformer configuration may not include '
          'reserved key "$reserved".');
    }
  }

  // TODO(nweiz): support deep equality on [configuration] as well.
  bool operator==(other) => other is TransformerId &&
      other.package == package &&
      other.path == path &&
      other.configuration == configuration;

  int get hashCode => package.hashCode ^ path.hashCode ^ configuration.hashCode;

  String toString() => path == null ? package : '$package/$path';

  /// Returns the asset id for the library identified by this transformer id.
  ///
  /// If `path` is null, this will determine which library to load.
  Future<AssetId> getAssetId(Barback barback) {
    if (path != null) {
      return new Future.value(new AssetId(package, 'lib/$path.dart'));
    }

    var transformerAsset = new AssetId(package, 'lib/transformer.dart');
    return barback.getAssetById(transformerAsset).then((_) => transformerAsset)
        .catchError((e) => new AssetId(package, 'lib/$package.dart'),
            test: (e) => e is AssetNotFoundException);
  }
}

/// Creates a [BarbackServer] serving on [host] and [port].
///
/// This transforms and serves all library and asset files in all packages in
/// [graph]. It loads any transformer plugins defined in packages in [graph] and
/// re-runs them as necessary when any input files change.
///
/// If [builtInTransformers] is provided, then a phase is added to the end of
/// each package's cascade including those transformers.
///
/// If [watchForUpdates] is true (the default), the server will continually
/// monitor the app and its dependencies for any updates. Otherwise the state of
/// the app when the server is started will be maintained.
Future<BarbackServer> createServer(String host, int port, PackageGraph graph,
    {Iterable<Transformer> builtInTransformers, bool watchForUpdates: true}) {
  var provider = new PubPackageProvider(graph);
  var barback = new Barback(provider);

  barback.log.listen(_log);

  return BarbackServer.bind(host, port, barback, graph.entrypoint.root.name)
      .then((server) {
    return new Future.sync(() {
      if (watchForUpdates) return watchSources(graph, barback);
      loadSources(graph, barback);
    }).then((_) {
      var completer = new Completer();

      // If any errors get emitted either by barback or by the server, including
      // non-programmatic barback errors, they should take down the whole
      // program.
      var subscriptions = [
        server.barback.errors.listen((error) {
          if (error is TransformerException) error = error.error;
          if (!completer.isCompleted) completer.completeError(error);
        }),
        server.barback.results.listen((_) {}, onError: (error, stackTrace) {
          if (completer.isCompleted) return;
          completer.completeError(error, stackTrace);
        }),
        server.results.listen((_) {}, onError: (error, stackTrace) {
          if (completer.isCompleted) return;
          completer.completeError(error, stackTrace);
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
  });
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

/// Log [entry] using Pub's logging infrastructure.
///
/// Since both [LogEntry] objects and the message itself often redundantly
/// show the same context like the file where an error occurred, this tries
/// to avoid showing redundant data in the entry.
void _log(LogEntry entry) {
  messageMentions(String text) {
    return entry.message.toLowerCase().contains(text.toLowerCase());
  }

  var prefixParts = [];

  // Show the level (unless the message mentions it).
  if (!messageMentions(entry.level.name)) {
    prefixParts.add("${entry.level} in");
  }

  // Show the transformer.
  prefixParts.add(entry.transform.transformer);

  // Mention the primary input of the transform unless the message seems to.
  if (!messageMentions(entry.transform.primaryId.path)) {
    prefixParts.add("on ${entry.transform.primaryId}");
  }

  // If the relevant asset isn't the primary input, mention it unless the
  // message already does.
  if (entry.assetId != entry.transform.primaryId &&
      !messageMentions(entry.assetId.path)) {
    prefixParts.add("with input ${entry.assetId}");
  }

  var prefix = "[${prefixParts.join(' ')}]:";
  var message = entry.message;
  if (entry.span != null) {
    message = entry.span.getLocationMessage(entry.message);
  }

  switch (entry.level) {
    case LogLevel.ERROR:
      log.error("${log.red(prefix)}\n$message");
      break;

    case LogLevel.WARNING:
      log.warning("${log.yellow(prefix)}\n$message");
      break;

    case LogLevel.INFO:
      log.message("$prefix\n$message");
      break;
  }
}