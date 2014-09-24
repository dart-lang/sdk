library pub.barback.asset_environment;
import 'dart:async';
import 'dart:io';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';
import '../cached_package.dart';
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
      graph = _adjustPackageGraph(graph, mode, packages);
      var barback = new Barback(new PubPackageProvider(graph));
      barback.log.listen(_log);
      var environment =
          new AssetEnvironment._(graph, barback, mode, watcherType, hostname, basePort);
      return environment._load(useDart2JS: useDart2JS).then((_) => environment);
    });
  }
  static PackageGraph _adjustPackageGraph(PackageGraph graph, BarbackMode mode,
      Iterable<String> packages) {
    if (mode != BarbackMode.DEBUG && packages == null) return graph;
    packages = (packages == null ? graph.packages.keys : packages).toSet();
    return new PackageGraph(
        graph.entrypoint,
        graph.lockFile,
        new Map.fromIterable(packages, value: (packageName) {
      var package = graph.packages[packageName];
      if (mode != BarbackMode.DEBUG) return package;
      var cache = path.join('.pub/deps/debug', packageName);
      if (!dirExists(cache)) return package;
      return new CachedPackage(package, cache);
    }));
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
  Set<AssetId> _modifiedSources;
  AssetEnvironment._(this.graph, this.barback, this.mode, this._watcherType,
      this._hostname, this._basePort);
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
  Future<Map<String, String>> precompileExecutables(String packageName,
      String directory, {Iterable<AssetId> executableIds}) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        join0() {
          log.fine("Executables for ${packageName}: ${executableIds}");
          join1() {
            var package = graph.packages[packageName];
            servePackageBinDirectory(packageName).then((x0) {
              try {
                var server = x0;
                join2(x1) {
                  completer0.complete(null);
                }
                finally0(cont0, v0) {
                  server.close();
                  cont0(v0);
                }
                catch0(e1) {
                  finally0(join2, null);
                }
                try {
                  var precompiled = {};
                  waitAndPrintErrors(executableIds.map(((id) {
                    final completer0 = new Completer();
                    scheduleMicrotask(() {
                      try {
                        var basename = path.url.basename(id.path);
                        var snapshotPath =
                            path.join(directory, "${basename}.snapshot");
                        runProcess(
                            Platform.executable,
                            [
                                '--snapshot=${snapshotPath}',
                                server.url.resolve(basename).toString()]).then((x0) {
                          try {
                            var result = x0;
                            join0() {
                              completer0.complete(null);
                            }
                            if (result.success) {
                              log.message(
                                  "Precompiled ${_formatExecutable(id)}.");
                              precompiled[path.withoutExtension(basename)] =
                                  snapshotPath;
                              join0();
                            } else {
                              completer0.completeError(
                                  new ApplicationException(
                                      log.yellow("Failed to precompile ${_formatExecutable(id)}:\n") +
                                          result.stderr.join('\n')));
                            }
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
                  }))).then((x2) {
                    try {
                      x2;
                      finally0((v1) {
                        completer0.complete(v1);
                      }, precompiled);
                    } catch (e2) {
                      catch0(e2);
                    }
                  }, onError: (e3) {
                    catch0(e3);
                  });
                } catch (e4) {
                  catch0(e4);
                }
              } catch (e0) {
                completer0.completeError(e0);
              }
            }, onError: (e5) {
              completer0.completeError(e5);
            });
          }
          if (executableIds.isEmpty) {
            completer0.complete([]);
          } else {
            join1();
          }
        }
        if (executableIds == null) {
          executableIds = graph.packages[packageName].executableIds;
          join0();
        } else {
          join0();
        }
      } catch (e6) {
        completer0.completeError(e6);
      }
    });
    return completer0.future;
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
    if (!graph.packages.containsKey(components[1])) return new Future.value([]);
    return Future.wait(_directories.values.map((dir) {
      return dir.server.then(
          (server) => server.url.resolveUri(path.toUri(assetPath)));
    }));
  }
  Future<List<Uri>> _lookUpPathInDependency(String assetPath) {
    for (var packageName in graph.packages.keys) {
      var package = graph.packages[packageName];
      var libDir = package.path('lib');
      var assetDir = package.path('asset');
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
      var transformerServer;
      return BarbackServer.bind(this, _hostname, 0).then((server) {
        transformerServer = server;
        var errorStream = barback.errors.map((error) {
          if (error is! AssetLoadException) throw error;
          log.error(log.red(error.message));
          log.fine(error.stackTrace.terse);
        });
        return _withStreamErrors(() {
          return log.progress("Loading source assets", _provideSources);
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
      });
    }, fine: true);
  }
  Future _provideSources() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        Future.wait(graph.packages.values.map(((package) {
          final completer0 = new Completer();
          scheduleMicrotask(() {
            try {
              join0() {
                _provideDirectorySources(package, "lib").then((x0) {
                  try {
                    x0;
                    completer0.complete(null);
                  } catch (e0) {
                    completer0.completeError(e0);
                  }
                }, onError: (e1) {
                  completer0.completeError(e1);
                });
              }
              if (graph.isPackageStatic(package.name)) {
                completer0.complete(null);
              } else {
                join0();
              }
            } catch (e2) {
              completer0.completeError(e2);
            }
          });
          return completer0.future;
        }))).then((x0) {
          try {
            x0;
            completer0.complete(null);
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
      var relative = package.relative(file);
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
    var subdirectory = package.path(dir);
    if (!dirExists(subdirectory)) return new Future.value();
    var watcher = _watcherType.create(subdirectory);
    var subscription = watcher.events.listen((event) {
      var parts = path.split(event.path);
      if (parts.contains("packages")) return;
      if (event.path.endsWith(".dart.js")) return;
      if (event.path.endsWith(".dart.js.map")) return;
      if (event.path.endsWith(".dart.precompiled.js")) return;
      var idPath = package.relative(event.path);
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
        (stream) => stream.listen((_) {}, onError: completer.completeError)).toList();
    new Future.sync(futureCallback).then((_) {
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
