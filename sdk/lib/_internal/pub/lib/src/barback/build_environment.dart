// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.build_environment;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:watcher/watcher.dart';

import '../entrypoint.dart';
import '../io.dart';
import '../log.dart' as log;
import '../package.dart';
import '../package_graph.dart';
import '../utils.dart';
import 'dart_forwarding_transformer.dart';
import 'dart2js_transformer.dart';
import 'load_all_transformers.dart';
import 'pub_package_provider.dart';
import 'server.dart';

/// The entire "visible" state of the assets of a package and all of its
/// dependencies, taking into account the user's configuration when running pub.
///
/// Where [PackageGraph] just describes the entrypoint's dependencies as
/// specified by pubspecs, this includes "transient" information like the mode
/// that the user is running pub in, or which directories they want to build.
class BuildEnvironment {
  /// Creates a new build environment for working with the assets used by
  /// [entrypoint] and its dependencies.
  ///
  /// Spawns an HTTP server for each directory in [rootDirectories]. These
  /// servers will be on [hostname] and have ports based on [basePort].
  /// [basePort] itself is reserved for "web/" and `basePort + 1` is reserved
  /// for "test/"; further ports will be allocated for other root directories as
  /// necessary. If [basePort] is zero, each server will have an ephemeral port.
  ///
  /// Loads all used transformers using [mode] (including dart2js if
  /// [useDart2JS] is true).
  ///
  /// Includes [rootDirectories] in the root package, as well as "lib" and
  /// "asset".
  ///
  /// If [watcherType] is not [WatcherType.NONE], watches source assets for
  /// modification.
  ///
  /// Returns a [Future] that completes to the environment once the inputs,
  /// transformers, and server are loaded and ready.
  static Future<BuildEnvironment> create(Entrypoint entrypoint,
      String hostname, int basePort, BarbackMode mode, WatcherType watcherType,
      Iterable<String> rootDirectories,
      {bool useDart2JS: true}) {
    return entrypoint.loadPackageGraph().then((graph) {
      var barback = new Barback(new PubPackageProvider(graph));
      barback.log.listen(_log);

      var environment = new BuildEnvironment._(graph, barback, mode,
          watcherType, rootDirectories);
      return environment._startServers(hostname, basePort).then((_) {
        // If the entrypoint package manually configures the dart2js
        // transformer, don't include it in the built-in transformer list.
        //
        // TODO(nweiz): if/when we support more built-in transformers, make
        // this more general.
        var containsDart2JS = graph.entrypoint.root.pubspec.transformers
            .any((transformers) => transformers
            .any((id) => id.package == '\$dart2js'));

        if (!containsDart2JS && useDart2JS) {
          environment._builtInTransformers.addAll([
            new Dart2JSTransformer(environment, mode),
            new DartForwardingTransformer(mode)
          ]);
        }

        return environment._load(barback).then((_) => environment);
      });
    });
  }

  /// Start the [BarbackServer]s that will serve [rootDirectories].
  Future<List<BarbackServer>> _startServers(String hostname, int basePort) {
    _bind(port, rootDirectory) {
      if (basePort == 0) port = 0;
      return BarbackServer.bind(this, hostname, port, rootDirectory);
    }

    var rootDirectoryList = _rootDirectories.toList();

    // For consistency, "web/" should always have the first available port and
    // "test/" should always have the second. Other directories are assigned
    // the following ports in alphabetical order.
    var serverFutures = [];
    if (rootDirectoryList.remove('web')) {
      serverFutures.add(_bind(basePort, 'web'));
    }
    if (rootDirectoryList.remove('test')) {
      serverFutures.add(_bind(basePort + 1, 'test'));
    }

    var i = 0;
    for (var dir in rootDirectoryList) {
      serverFutures.add(_bind(basePort + 2 + i, dir));
      i += 1;
    }

    return Future.wait(serverFutures).then((boundServers) {
      servers.addAll(boundServers);
    });
  }

  /// The servers serving this environment's assets.
  final servers = <BarbackServer>[];

  /// The [Barback] instance used to process assets in this environment.
  final Barback barback;

  /// The root package being built.
  Package get rootPackage => graph.entrypoint.root;

  /// The underlying [PackageGraph] being built.
  final PackageGraph graph;

  /// The mode to run the transformers in.
  final BarbackMode mode;

  /// The [Transformer]s that should be appended by default to the root
  /// package's transformer cascade. Will be empty if there are none.
  final _builtInTransformers = <Transformer>[];

  /// How source files should be watched.
  final WatcherType _watcherType;

  /// The set of top-level directories in the entrypoint package that will be
  /// exposed.
  final Set<String> _rootDirectories;

  BuildEnvironment._(this.graph, this.barback, this.mode, this._watcherType,
      Iterable<String> rootDirectories)
      : _rootDirectories = rootDirectories.toSet();

  /// Gets the built-in [Transformer]s that should be added to [package].
  ///
  /// Returns `null` if there are none.
  Iterable<Transformer> getBuiltInTransformers(Package package) {
    // Built-in transformers only apply to the root package.
    if (package.name != rootPackage.name) return null;

    // The built-in transformers are for dart2js and forwarding assets around
    // dart2js.
    if (_builtInTransformers.isEmpty) return null;

    return _builtInTransformers;
  }

  /// Loads the assets and transformers for this environment.
  ///
  /// This transforms and serves all library and asset files in all packages in
  /// the environment's package graph. It loads any transformer plugins defined
  /// in packages in [graph] and re-runs them as necessary when any input files
  /// change.
  ///
  /// Returns a [Future] that completes once all inputs and transformers are
  /// loaded.
  Future _load(Barback barback) {
    return _provideSources(barback).then((_) {
      var completer = new Completer();

      // If any errors get emitted either by barback or by the primary server,
      // including non-programmatic barback errors, they should take down the
      // whole program.
      var subscriptions = [
        barback.errors.listen((error) {
          if (error is TransformerException) error = error.error;
          if (!completer.isCompleted) {
            completer.completeError(error, new Chain.current());
          }
        }),
        barback.results.listen((_) {},
            onError: (error, stackTrace) {
          if (completer.isCompleted) return;
          completer.completeError(error, stackTrace);
        }),
        // We only listen to the first server here because that's the one used
        // to initialize all the transformers during the initial load.
        servers.first.results.listen((_) {}, onError: (error, stackTrace) {
          if (completer.isCompleted) return;
          completer.completeError(error, stackTrace);
        })
      ];

      loadAllTransformers(this).then((_) {
        if (!completer.isCompleted) completer.complete();
      }).catchError((error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      });

      return completer.future.whenComplete(() {
        for (var subscription in subscriptions) {
          subscription.cancel();
        }
      });
    });
  }

  /// Provides all of the source assets in the environment to barback.
  ///
  /// If [watcherType] is not [WatcherType.NONE], enables watching on them.
  Future _provideSources(Barback barback) {
    if (_watcherType != WatcherType.NONE) {
      return _watchSources(barback);
    }

    return syncFuture(() {
      _loadSources(barback);
    });
  }

  /// Provides all of the source assets in the environment to barback.
  void _loadSources(Barback barback) {
    for (var package in graph.packages.values) {
      barback.updateSources(_listAssets(graph.entrypoint, package));
    }
  }

  /// Adds all of the source assets in this environment to barback and then
  /// watches the public directories for changes.
  ///
  /// Returns a Future that completes when the sources are loaded and the
  /// watchers are active.
  Future _watchSources(Barback barback) {
    return Future.wait(graph.packages.values.map((package) {
      // If this package comes from a cached source, its contents won't change
      // so we don't need to monitor it. `packageId` will be null for the
      // application package, since that's not locked.
      var packageId = graph.lockFile.packages[package.name];
      if (packageId != null &&
          graph.entrypoint.cache.sources[packageId.source].shouldCache) {
        barback.updateSources(_listAssets(graph.entrypoint, package));
        return new Future.value();
      }

      // Watch the visible package directories for changes.
      return Future.wait(_getPublicDirectories(graph.entrypoint, package)
          .map((name) {
        var subdirectory = path.join(package.dir, name);
        if (!dirExists(subdirectory)) return new Future.value();

        // TODO(nweiz): close these watchers when [barback] is closed.
        var watcher = _watcherType.create(subdirectory);
        watcher.events.listen((event) {
          // Don't watch files symlinked into these directories.
          // TODO(rnystrom): If pub gets rid of symlinks, remove this.
          var parts = path.split(event.path);
          if (parts.contains("packages") || parts.contains("assets")) return;

          // Skip files that were (most likely) compiled from nearby ".dart"
          // files. These are created by the Editor's "Run as JavaScript"
          // command and are written directly into the package's directory.
          // When pub's dart2js transformer then tries to create the same file
          // name, we get a build error. To avoid that, just don't consider
          // that file to be a source.
          // TODO(rnystrom): Remove these when the Editor no longer generates
          // .js files and users have had enough time that they no longer have
          // these files laying around. See #15859.
          if (event.path.endsWith(".dart.js")) return;
          if (event.path.endsWith(".dart.js.map")) return;
          if (event.path.endsWith(".dart.precompiled.js")) return;

          var id = new AssetId(package.name,
              path.relative(event.path, from: package.dir));
          if (event.type == ChangeType.REMOVE) {
            barback.removeSources([id]);
          } else {
            barback.updateSources([id]);
          }
        });
        return watcher.ready;
      })).then((_) {
        barback.updateSources(_listAssets(graph.entrypoint, package));
      });
    }));
  }

  /// Lists all of the visible files in [package].
  ///
  /// This is the recursive contents of the "asset" and "lib" directories (if
  /// present). If [package] is the entrypoint package, it also includes the
  /// contents of "web".
  List<AssetId> _listAssets(Entrypoint entrypoint, Package package) {
    var files = <AssetId>[];

    for (var dirPath in _getPublicDirectories(entrypoint, package)) {
      var dir = path.join(package.dir, dirPath);
      if (!dirExists(dir)) continue;
      for (var entry in listDir(dir, recursive: true)) {
        // Ignore "packages" symlinks if there.
        if (path.split(entry).contains("packages")) continue;

        // Skip directories.
        if (!fileExists(entry)) continue;

        // Skip files that were (most likely) compiled from nearby ".dart"
        // files. These are created by the Editor's "Run as JavaScript"
        // command and are written directly into the package's directory.
        // When pub's dart2js transformer then tries to create the same file
        // name, we get a build error. To avoid that, just don't consider
        // that file to be a source.
        // TODO(rnystrom): Remove these when the Editor no longer generates
        // .js files and users have had enough time that they no longer have
        // these files laying around. See #15859.
        if (entry.endsWith(".dart.js")) continue;
        if (entry.endsWith(".dart.js.map")) continue;
        if (entry.endsWith(".dart.precompiled.js")) continue;

        var id = new AssetId(package.name,
            path.relative(entry, from: package.dir));
        files.add(id);
      }
    }

    return files;
  }

  /// Gets the names of the top-level directories in [package] whose contents
  /// should be provided as source assets.
  Iterable<String> _getPublicDirectories(Entrypoint entrypoint,
      Package package) {
    var directories = ["asset", "lib"];

    if (package.name == entrypoint.root.name) {
      directories.addAll(_rootDirectories);
    }

    return directories;
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
    prefixParts.add("${entry.level} from");
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
      log.message("${log.cyan(prefix)}\n$message");
      break;

    case LogLevel.FINE:
      log.fine("${log.gray(prefix)}\n$message");
      break;
  }
}

/// An enum describing different modes of constructing a [DirectoryWatcher].
abstract class WatcherType {
  /// A watcher that automatically chooses its type based on the operating
  /// system.
  static const AUTO = const _AutoWatcherType();

  /// A watcher that always polls the filesystem for changes.
  static const POLLING = const _PollingWatcherType();

  /// No directory watcher at all.
  static const NONE = const _NoneWatcherType();

  /// Creates a new DirectoryWatcher.
  DirectoryWatcher create(String directory);

  String toString();
}

class _AutoWatcherType implements WatcherType {
  const _AutoWatcherType();

  DirectoryWatcher create(String directory) =>
    new DirectoryWatcher(directory);

  String toString() => "auto";
}

class _PollingWatcherType implements WatcherType {
  const _PollingWatcherType();

  DirectoryWatcher create(String directory) =>
    new PollingDirectoryWatcher(directory);

  String toString() => "polling";
}

class _NoneWatcherType implements WatcherType {
  const _NoneWatcherType();

  DirectoryWatcher create(String directory) => null;

  String toString() => "none";
}
