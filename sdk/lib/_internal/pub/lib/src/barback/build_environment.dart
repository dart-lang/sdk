// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.build_environment;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:watcher/watcher.dart';

import '../entrypoint.dart';
import '../io.dart';
import '../log.dart' as log;
import '../package.dart';
import '../package_graph.dart';
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
      {bool useDart2JS: true}) {
    return entrypoint.loadPackageGraph().then((graph) {
      log.fine("Loaded package graph.");
      var barback = new Barback(new PubPackageProvider(graph));
      barback.log.listen(_log);

      var environment = new BuildEnvironment._(graph, barback, mode,
          watcherType, hostname, basePort);

      return environment._load(useDart2JS: useDart2JS)
          .then((_) => environment);
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

  /// The hostname that servers are bound to.
  final String _hostname;

  /// The starting number for ports that servers will be bound to.
  ///
  /// Servers will be bound to ports starting at this number and then
  /// incrementing from there. However, if this is zero, then ephemeral port
  /// numbers will be selected for each server.
  final int _basePort;

  /// The modified source assets that have not been sent to barback yet.
  ///
  /// The build environment can be paused (by calling [pauseUpdates]) and
  /// resumed ([resumeUpdates]). While paused, all source asset updates that
  /// come from watching or adding new directories are not sent to barback.
  /// When resumed, all pending source updates are sent to barback.
  ///
  /// This lets pub serve and pub build create an environment and bind several
  /// servers before barback starts building and producing results
  /// asynchronously.
  ///
  /// If this is `null`, then the environment is "live" and all updates will
  /// go to barback immediately.
  Set<AssetId> _modifiedSources;

  BuildEnvironment._(this.graph, this.barback, this.mode, this._watcherType,
      this._hostname, this._basePort);

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

  /// Binds a new port to serve assets from within [rootDirectory] in the
  /// entrypoint package.
  ///
  /// Adds and watches the sources within that directory. Returns a [Future]
  /// that completes to the bound server.
  ///
  /// If [rootDirectory] is already being served, returns that existing server.
  Future<BarbackServer> serveDirectory(String rootDirectory) {
    // See if there is already a server bound to the directory.
    var server = servers.firstWhere(
        (server) => server.rootDirectory == rootDirectory, orElse: () => null);
    if (server != null) return new Future.value(server);

    return _provideDirectorySources(rootPackage, rootDirectory).then((_) {
      var port = _basePort;

      // If not using an ephemeral port, find the lowest-numbered available one.
      if (port != 0) {
        var boundPorts = servers.map((server) => server.port).toSet();
        while (boundPorts.contains(port)) {
          port++;
        }
      }

      return BarbackServer.bind(this, _hostname, port, rootDirectory)
          .then((server) {
        servers.add(server);
        return server;
      });
    });
  }

  /// Determines if [sourcePath] is contained within any of the directories
  /// that are visible to this build environment.
  bool containsPath(String sourcePath) {
    return _getPublicDirectories(rootPackage.name)
        .any((dir) => path.isWithin(dir, sourcePath));
  }

  /// Pauses sending source asset updates to barback.
  void pauseUpdates() {
    // Cannot pause while already paused.
    assert(_modifiedSources == null);

    _modifiedSources = new Set<AssetId>();
  }

  /// Sends any pending source updates to barback and begins the asynchronous
  /// build process.
  void resumeUpdates() {
    // Cannot resume while not paused.
    assert(_modifiedSources != null);

    barback.updateSources(_modifiedSources);
    _modifiedSources = null;
  }

  /// Gets the names of the top-level directories in [package] whose contents
  /// should be provided as source assets.
  Set<String> _getPublicDirectories(String package) {
    var directories = ["asset", "lib"];

    if (package == graph.entrypoint.root.name) {
      directories.addAll(servers.map((server) => server.rootDirectory));
    }

    return directories.toSet();
  }

  /// Loads the assets and transformers for this environment.
  ///
  /// This transforms and serves all library and asset files in all packages in
  /// the environment's package graph. It loads any transformer plugins defined
  /// in packages in [graph] and re-runs them as necessary when any input files
  /// change.
  ///
  /// If [useDart2JS] is `true`, then the [Dart2JSTransformer] is implicitly
  /// added to end of the root package's transformer phases.
  ///
  /// Returns a [Future] that completes once all inputs and transformers are
  /// loaded.
  Future _load({bool useDart2JS}) {
    // If the entrypoint package manually configures the dart2js
    // transformer, don't include it in the built-in transformer list.
    //
    // TODO(nweiz): if/when we support more built-in transformers, make
    // this more general.
    var containsDart2JS = graph.entrypoint.root.pubspec.transformers
        .any((transformers) => transformers
        .any((id) => id.package == '\$dart2js'));

    if (!containsDart2JS && useDart2JS) {
      _builtInTransformers.addAll([
        new Dart2JSTransformer(this, mode),
        new DartForwardingTransformer(mode)
      ]);
    }

    // "$pub" is a psuedo-package that allows pub's transformer-loading
    // infrastructure to share code with pub proper. We provide it only during
    // the initial transformer loading process.
    var dartPath = assetPath('dart');
    var pubSources = listDir(dartPath).map((library) {
      return new AssetId('\$pub',
          path.join('lib', path.relative(library, from: dartPath)));
    });

    // Bind a server that we can use to load the transformers.
    var transformerServer;
    return BarbackServer.bind(this, _hostname, 0, null).then((server) {
      transformerServer = server;

      return log.progress("Loading source assets", () {
        barback.updateSources(pubSources);
        return _provideSources();
      });
    }).then((_) {
      log.fine("Provided sources.");
      var completer = new Completer();

      // If any errors get emitted either by barback or by the transformer
      // server, including non-programmatic barback errors, they should take
      // down the whole program.
      var subscriptions = [
        barback.errors.listen((error) {
          if (error is TransformerException) {
            var message = error.error.toString();
            if (error.stackTrace != null) {
              message += "\n" + error.stackTrace.terse.toString();
            }

            _log(new LogEntry(error.transform, error.transform.primaryId,
                LogLevel.ERROR, message, null));
          } else if (!completer.isCompleted) {
            completer.completeError(error, new Chain.current());
          }
        }),
        barback.results.listen((_) {},
            onError: (error, stackTrace) {
          if (completer.isCompleted) return;
          completer.completeError(error, stackTrace);
        }),
        transformerServer.results.listen((_) {}, onError: (error, stackTrace) {
          if (completer.isCompleted) return;
          completer.completeError(error, stackTrace);
        })
      ];

      loadAllTransformers(this, transformerServer).then((_) {
        log.fine("Loaded transformers.");
        return transformerServer.close();
      }).then((_) {
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
    }).then((_) => barback.removeSources(pubSources));
  }

  /// Provides all of the source assets in the environment to barback.
  ///
  /// If [watcherType] is not [WatcherType.NONE], enables watching on them.
  Future _provideSources() {
    return Future.wait(graph.packages.values.map((package) {
      return Future.wait(_getPublicDirectories(package.name)
          .map((dir) => _provideDirectorySources(package, dir)));
    }));
  }

  /// Provides all of the source assets within [dir] in [package] to barback.
  ///
  /// If [watcherType] is not [WatcherType.NONE], enables watching on them.
  Future _provideDirectorySources(Package package, String dir) {
    // TODO(rnystrom): Handle overlapping directories. If two served
    // directories overlap like so:
    //
    // $ pub serve example example/subdir
    //
    // Then the sources of the subdirectory will be updated and watched twice.
    // See: #17454
    return _updateDirectorySources(package, dir).then((_) {
      if (_watcherType == WatcherType.NONE) return null;
      return _watchDirectorySources(package, dir);
    });
  }

  /// Updates barback with all of the files in [dir] inside [package].
  ///
  /// For large packages, listing the contents is a performance bottleneck, so
  /// this is optimized for our needs in here instead of using the more general
  /// but slower [listDir].
  Future _updateDirectorySources(Package package, String dir) {
    var subdirectory = path.join(package.dir, dir);
    if (!dirExists(subdirectory)) return new Future.value();

    return new Directory(subdirectory).list(recursive: true, followLinks: true)
        .expand((entry) {
      // Skip directories and (broken) symlinks.
      if (entry is Directory) return [];
      if (entry is Link) return [];

      var relative = path.normalize(
          path.relative(entry.path, from: package.dir));

      // Ignore hidden files or files in "packages" and hidden directories.
      if (path.split(relative).any((part) =>
          part.startsWith(".") || part == "packages")) {
        return [];
      }

      // Skip files that were (most likely) compiled from nearby ".dart"
      // files. These are created by the Editor's "Run as JavaScript"
      // command and are written directly into the package's directory.
      // When pub's dart2js transformer then tries to create the same file
      // name, we get a build error. To avoid that, just don't consider
      // that file to be a source.
      // TODO(rnystrom): Remove these when the Editor no longer generates
      // .js files and users have had enough time that they no longer have
      // these files laying around. See #15859.
      if (relative.endsWith(".dart.js")) return [];
      if (relative.endsWith(".dart.js.map")) return [];
      if (relative.endsWith(".dart.precompiled.js")) return [];

      return [new AssetId(package.name, relative)];
    }).toList().then((ids) {
      if (_modifiedSources == null) {
        barback.updateSources(ids);
      } else {
        _modifiedSources.addAll(ids);
      }
    });
  }

  /// Adds a file watcher for [dir] within [package], if the directory exists
  /// and the package needs watching.
  Future _watchDirectorySources(Package package, String dir) {
    // If this package comes from a cached source, its contents won't change so
    // we don't need to monitor it. `packageId` will be null for the
    // application package, since that's not locked.
    var packageId = graph.lockFile.packages[package.name];
    if (packageId != null &&
        graph.entrypoint.cache.sources[packageId.source].shouldCache) {
      return new Future.value();
    }

    var subdirectory = path.join(package.dir, dir);
    if (!dirExists(subdirectory)) return new Future.value();

    // TODO(nweiz): close this watcher when [barback] is closed.
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
        if (_modifiedSources != null) {
          _modifiedSources.remove(id);
        } else {
          barback.removeSources([id]);
        }
      } else if (_modifiedSources != null) {
        _modifiedSources.add(id);
      } else {
        barback.updateSources([id]);
      }
    });

    return watcher.ready;
  }
}

/// Log [entry] using Pub's logging infrastructure.
///
/// Since both [LogEntry] objects and the message itself often redundantly
/// show the same context like the file where an error occurred, this tries
/// to avoid showing redundant data in the entry.
void _log(LogEntry entry) {
  messageMentions(text) =>
      entry.message.toLowerCase().contains(text.toLowerCase());

  messageMentionsAsset(id) =>
      messageMentions(id.toString()) ||
      messageMentions(path.joinAll(path.url.split(entry.assetId.path)));

  var prefixParts = [];

  // Show the level (unless the message mentions it).
  if (!messageMentions(entry.level.name)) {
    prefixParts.add("${entry.level} from");
  }

  // Show the transformer.
  prefixParts.add(entry.transform.transformer);

  // Mention the primary input of the transform unless the message seems to.
  if (!messageMentionsAsset(entry.transform.primaryId)) {
    prefixParts.add("on ${entry.transform.primaryId}");
  }

  // If the relevant asset isn't the primary input, mention it unless the
  // message already does.
  if (entry.assetId != entry.transform.primaryId &&
      !messageMentionsAsset(entry.assetId)) {
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
