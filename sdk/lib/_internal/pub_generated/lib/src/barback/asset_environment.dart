library pub.barback.asset_environment;
import 'dart:async';
import 'dart:io';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';
import '../entrypoint.dart';
import '../exceptions.dart';
import '../io.dart';
import '../log.dart' as log;
import '../package.dart';
import '../package_graph.dart';
import '../sdk.dart' as sdk;
import '../source/cached.dart';
import '../utils.dart';
import 'admin_server.dart';
import 'barback_server.dart';
import 'dart_forwarding_transformer.dart';
import 'dart2js_transformer.dart';
import 'load_all_transformers.dart';
import 'pub_package_provider.dart';
import 'source_directory.dart';
class AssetEnvironment {
  static Future<AssetEnvironment> create(Entrypoint entrypoint,
      BarbackMode mode, {WatcherType watcherType, String hostname, int basePort,
      Iterable<String> packages, bool useDart2JS: true}) {
    if (watcherType == null) watcherType = WatcherType.NONE;
    if (hostname == null) hostname = "localhost";
    if (basePort == null) basePort = 0;
    return entrypoint.loadPackageGraph().then((graph) {
      log.fine("Loaded package graph.");
      var barback = new Barback(new PubPackageProvider(graph, packages));
      barback.log.listen(_log);
      var environment = new AssetEnvironment._(
          graph,
          barback,
          mode,
          watcherType,
          hostname,
          basePort,
          packages);
      return environment._load(useDart2JS: useDart2JS).then((_) => environment);
    });
  }
  AdminServer _adminServer;
  final _directories = new Map<String, SourceDirectory>();
  final Barback barback;
  Package get rootPackage => graph.entrypoint.root;
  final PackageGraph graph;
  final BarbackMode mode;
  final _builtInTransformers = <Transformer>[];
  final WatcherType _watcherType;
  final String _hostname;
  final int _basePort;
  final Set<String> packages;
  Set<AssetId> _modifiedSources;
  AssetEnvironment._(PackageGraph graph, this.barback, this.mode,
      this._watcherType, this._hostname, this._basePort, Iterable<String> packages)
      : graph = graph,
        packages = packages == null ?
          graph.packages.keys.toSet() :
          packages.toSet();
  Iterable<Transformer> getBuiltInTransformers(Package package) {
    if (package.name != rootPackage.name) return null;
    if (_builtInTransformers.isEmpty) return null;
    return _builtInTransformers;
  }
  Future<AdminServer> startAdminServer([int port]) {
    assert(_adminServer == null);
    if (port == null) port = _basePort == 0 ? 0 : _basePort - 1;
    return AdminServer.bind(this, _hostname, port).then((server) => _adminServer =
        server);
  }
  Future<BarbackServer> serveDirectory(String rootDirectory) {
    var directory = _directories[rootDirectory];
    if (directory != null) {
      return directory.server.then((server) {
        log.fine('Already serving $rootDirectory on ${server.url}.');
        return server;
      });
    }
    var overlapping = _directories.keys.where(
        (directory) =>
            path.isWithin(directory, rootDirectory) ||
                path.isWithin(rootDirectory, directory)).toList();
    if (overlapping.isNotEmpty) {
      return new Future.error(
          new OverlappingSourceDirectoryException(overlapping));
    }
    var port = _basePort;
    if (port != 0) {
      var boundPorts =
          _directories.values.map((directory) => directory.port).toSet();
      while (boundPorts.contains(port)) {
        port++;
      }
    }
    var sourceDirectory =
        new SourceDirectory(this, rootDirectory, _hostname, port);
    _directories[rootDirectory] = sourceDirectory;
    return _provideDirectorySources(
        rootPackage,
        rootDirectory).then((subscription) {
      sourceDirectory.watchSubscription = subscription;
      return sourceDirectory.serve();
    });
  }
  Future<BarbackServer> servePackageBinDirectory(String package) {
    return _provideDirectorySources(
        graph.packages[package],
        "bin").then(
            (_) =>
                BarbackServer.bind(this, _hostname, 0, package: package, rootDirectory: "bin"));
  }
  Future precompileExecutables(String packageName, String directory,
      {Iterable<AssetId> executableIds}) {
    if (executableIds == null) {
      executableIds = graph.packages[packageName].executableIds;
    }
    log.fine("executables for $packageName: $executableIds");
    if (executableIds.isEmpty) return null;
    var package = graph.packages[packageName];
    return servePackageBinDirectory(packageName).then((server) {
      return waitAndPrintErrors(executableIds.map((id) {
        var basename = path.url.basename(id.path);
        var snapshotPath = path.join(directory, "$basename.snapshot");
        return runProcess(
            Platform.executable,
            [
                '--snapshot=$snapshotPath',
                server.url.resolve(basename).toString()]).then((result) {
          if (result.success) {
            log.message("Precompiled ${_formatExecutable(id)}.");
          } else {
            throw new ApplicationException(
                log.yellow("Failed to precompile " "${_formatExecutable(id)}:\n") +
                    result.stderr.join('\n'));
          }
        });
      })).whenComplete(() {
        server.close();
      });
    });
  }
  String _formatExecutable(AssetId id) =>
      log.bold("${id.package}:${path.basenameWithoutExtension(id.path)}");
  Future<Uri> unserveDirectory(String rootDirectory) {
    log.fine("Unserving $rootDirectory.");
    var directory = _directories.remove(rootDirectory);
    if (directory == null) return new Future.value();
    return directory.server.then((server) {
      var url = server.url;
      return directory.close().then((_) {
        _removeDirectorySources(rootDirectory);
        return url;
      });
    });
  }
  String getSourceDirectoryContaining(String assetPath) =>
      _directories.values.firstWhere(
          (dir) => path.isWithin(dir.directory, assetPath)).directory;
  Future<List<Uri>> getUrlsForAssetPath(String assetPath) {
    return _lookUpPathInServerRoot(assetPath).then((urls) {
      if (urls.isNotEmpty) return urls;
      return _lookUpPathInPackagesDirectory(assetPath);
    }).then((urls) {
      if (urls.isNotEmpty) return urls;
      return _lookUpPathInDependency(assetPath);
    });
  }
  Future<List<Uri>> _lookUpPathInServerRoot(String assetPath) {
    return Future.wait(
        _directories.values.where(
            (dir) => path.isWithin(dir.directory, assetPath)).map((dir) {
      var relativePath = path.relative(assetPath, from: dir.directory);
      return dir.server.then(
          (server) => server.url.resolveUri(path.toUri(relativePath)));
    }));
  }
  Future<List<Uri>> _lookUpPathInPackagesDirectory(String assetPath) {
    var components = path.split(path.relative(assetPath));
    if (components.first != "packages") return new Future.value([]);
    if (!packages.contains(components[1])) return new Future.value([]);
    return Future.wait(_directories.values.map((dir) {
      return dir.server.then(
          (server) => server.url.resolveUri(path.toUri(assetPath)));
    }));
  }
  Future<List<Uri>> _lookUpPathInDependency(String assetPath) {
    for (var packageName in packages) {
      var package = graph.packages[packageName];
      var libDir = path.join(package.dir, 'lib');
      var assetDir = path.join(package.dir, 'asset');
      var uri;
      if (path.isWithin(libDir, assetPath)) {
        uri = path.toUri(
            path.join('packages', package.name, path.relative(assetPath, from: libDir)));
      } else if (path.isWithin(assetDir, assetPath)) {
        uri = path.toUri(
            path.join('assets', package.name, path.relative(assetPath, from: assetDir)));
      } else {
        continue;
      }
      return Future.wait(_directories.values.map((dir) {
        return dir.server.then((server) => server.url.resolveUri(uri));
      }));
    }
    return new Future.value([]);
  }
  Future<AssetId> getAssetIdForUrl(Uri url) {
    return Future.wait(
        _directories.values.map((dir) => dir.server)).then((servers) {
      var server = servers.firstWhere((server) {
        if (server.port != url.port) return false;
        return isLoopback(server.address.host) == isLoopback(url.host) ||
            server.address.host == url.host;
      }, orElse: () => null);
      if (server == null) return null;
      return server.urlToId(url);
    });
  }
  bool containsPath(String sourcePath) {
    var directories = ["lib"];
    directories.addAll(_directories.keys);
    return directories.any((dir) => path.isWithin(dir, sourcePath));
  }
  void pauseUpdates() {
    assert(_modifiedSources == null);
    _modifiedSources = new Set<AssetId>();
  }
  void resumeUpdates() {
    assert(_modifiedSources != null);
    barback.updateSources(_modifiedSources);
    _modifiedSources = null;
  }
  Future _load({bool useDart2JS}) {
    return log.progress("Initializing barback", () {
      var containsDart2JS = graph.entrypoint.root.pubspec.transformers.any(
          (transformers) =>
              transformers.any((config) => config.id.package == '\$dart2js'));
      if (!containsDart2JS && useDart2JS) {
        _builtInTransformers.addAll(
            [new Dart2JSTransformer(this, mode), new DartForwardingTransformer(mode)]);
      }
      var dartPath = assetPath('dart');
      var pubSources = listDir(
          dartPath,
          recursive: true).where(
              (file) => path.extension(file) == ".dart").map((library) {
        var idPath = path.join('lib', path.relative(library, from: dartPath));
        return new AssetId('\$pub', path.toUri(idPath).toString());
      });
      var libPath = path.join(sdk.rootDirectory, "lib");
      var sdkSources = listDir(
          libPath,
          recursive: true).where((file) => path.extension(file) == ".dart").map((file) {
        var idPath =
            path.join("lib", path.relative(file, from: sdk.rootDirectory));
        return new AssetId('\$sdk', path.toUri(idPath).toString());
      });
      var transformerServer;
      return BarbackServer.bind(this, _hostname, 0).then((server) {
        transformerServer = server;
        var errorStream = barback.errors.map((error) {
          if (error is! AssetLoadException) throw error;
          log.error(log.red(error.message));
          log.fine(error.stackTrace.terse);
        });
        return _withStreamErrors(() {
          return log.progress("Loading source assets", () {
            barback.updateSources(pubSources);
            barback.updateSources(sdkSources);
            return _provideSources();
          });
        }, [errorStream, barback.results]);
      }).then((_) {
        log.fine("Provided sources.");
        var completer = new Completer();
        var errorStream = barback.errors.map((error) {
          if (error is! TransformerException) throw error;
          var message = error.error.toString();
          if (error.stackTrace != null) {
            message += "\n" + error.stackTrace.terse.toString();
          }
          _log(
              new LogEntry(
                  error.transform,
                  error.transform.primaryId,
                  LogLevel.ERROR,
                  message,
                  null));
        });
        return _withStreamErrors(() {
          return log.progress("Loading transformers", () {
            return loadAllTransformers(
                this,
                transformerServer).then((_) => transformerServer.close());
          }, fine: true);
        }, [errorStream, barback.results, transformerServer.results]);
      }).then((_) => barback.removeSources(pubSources));
    }, fine: true);
  }
  Future _provideSources() {
    return Future.wait(packages.map((package) {
      return _provideDirectorySources(graph.packages[package], "lib");
    }));
  }
  Future<StreamSubscription<WatchEvent>>
      _provideDirectorySources(Package package, String dir) {
    log.fine("Providing sources for ${package.name}|$dir.");
    if (_watcherType == WatcherType.NONE) {
      _updateDirectorySources(package, dir);
      return new Future.value();
    }
    return _watchDirectorySources(package, dir).then((_) {
      _updateDirectorySources(package, dir);
    });
  }
  void _updateDirectorySources(Package package, String dir) {
    var ids = _listDirectorySources(package, dir);
    if (_modifiedSources == null) {
      barback.updateSources(ids);
    } else {
      _modifiedSources.addAll(ids);
    }
  }
  void _removeDirectorySources(String dir) {
    var ids = _listDirectorySources(rootPackage, dir);
    if (_modifiedSources == null) {
      barback.removeSources(ids);
    } else {
      _modifiedSources.removeAll(ids);
    }
  }
  Iterable<AssetId> _listDirectorySources(Package package, String dir) {
    return package.listFiles(beneath: dir).map((file) {
      var relative = path.relative(file, from: package.dir);
      if (Platform.operatingSystem == 'windows') {
        relative = relative.replaceAll("\\", "/");
      }
      var uri = new Uri(pathSegments: relative.split("/"));
      return new AssetId(package.name, uri.toString());
    });
  }
  Future<StreamSubscription<WatchEvent>> _watchDirectorySources(Package package,
      String dir) {
    var packageId = graph.lockFile.packages[package.name];
    if (packageId != null &&
        graph.entrypoint.cache.sources[packageId.source] is CachedSource) {
      return new Future.value();
    }
    var subdirectory = path.join(package.dir, dir);
    if (!dirExists(subdirectory)) return new Future.value();
    var watcher = _watcherType.create(subdirectory);
    var subscription = watcher.events.listen((event) {
      var parts = path.split(event.path);
      if (parts.contains("packages")) return;
      if (event.path.endsWith(".dart.js")) return;
      if (event.path.endsWith(".dart.js.map")) return;
      if (event.path.endsWith(".dart.precompiled.js")) return;
      var idPath = path.relative(event.path, from: package.dir);
      var id = new AssetId(package.name, path.toUri(idPath).toString());
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
    return watcher.ready.then((_) => subscription);
  }
  Future _withStreamErrors(Future futureCallback(), List<Stream> streams) {
    var completer = new Completer.sync();
    var subscriptions = streams.map(
        (stream) => stream.listen((_) {}, onError: completer.complete)).toList();
    syncFuture(futureCallback).then((_) {
      if (!completer.isCompleted) completer.complete();
    }).catchError((error, stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    });
    return completer.future.whenComplete(() {
      for (var subscription in subscriptions) {
        subscription.cancel();
      }
    });
  }
}
void _log(LogEntry entry) {
  messageMentions(text) =>
      entry.message.toLowerCase().contains(text.toLowerCase());
  messageMentionsAsset(id) =>
      messageMentions(id.toString()) ||
          messageMentions(path.fromUri(entry.assetId.path));
  var prefixParts = [];
  if (!messageMentions(entry.level.name)) {
    prefixParts.add("${entry.level} from");
  }
  prefixParts.add(entry.transform.transformer);
  if (!messageMentionsAsset(entry.transform.primaryId)) {
    prefixParts.add("on ${entry.transform.primaryId}");
  }
  if (entry.assetId != entry.transform.primaryId &&
      !messageMentionsAsset(entry.assetId)) {
    prefixParts.add("with input ${entry.assetId}");
  }
  var prefix = "[${prefixParts.join(' ')}]:";
  var message = entry.message;
  if (entry.span != null) {
    message = entry.span.message(entry.message);
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
class OverlappingSourceDirectoryException implements Exception {
  final List<String> overlappingDirectories;
  OverlappingSourceDirectoryException(this.overlappingDirectories);
}
abstract class WatcherType {
  static const AUTO = const _AutoWatcherType();
  static const POLLING = const _PollingWatcherType();
  static const NONE = const _NoneWatcherType();
  DirectoryWatcher create(String directory);
  String toString();
}
class _AutoWatcherType implements WatcherType {
  const _AutoWatcherType();
  DirectoryWatcher create(String directory) => new DirectoryWatcher(directory);
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
