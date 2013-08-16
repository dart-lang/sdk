// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.serve;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import '../command.dart';
import '../entrypoint.dart';
import '../exit_codes.dart' as exit_codes;
import '../io.dart';
import '../log.dart' as log;
import '../pub_package_provider.dart';
import '../utils.dart';

final _green = getPlatformString('\u001b[32m');
final _red = getPlatformString('\u001b[31m');
final _none = getPlatformString('\u001b[0m');

/// Handles the `serve` pub command.
class ServeCommand extends PubCommand {
  String get description => "Run a local web development server.";
  String get usage => 'pub serve';

  PubPackageProvider _provider;
  Barback _barback;

  /// The completer for the top-level future returned by the command.
  ///
  /// Only used to keep pub running (by not completing) and to pipe fatal
  /// errors to pub's top-level error-handling machinery.
  final _commandCompleter = new Completer();

  ServeCommand() {
    commandParser.addOption('port', defaultsTo: '8080',
        help: 'The port to listen on.');
  }

  Future onRun() {
    var port = parsePort();

    return ensureLockFileIsUpToDate().then((_) {
      return PubPackageProvider.create(entrypoint);
    }).then((provider) {
      _provider = provider;

      initBarback();

      HttpServer.bind("localhost", port).then((server) {
        watchSources();

        log.message("Serving ${entrypoint.root.name} "
            "on http://localhost:${server.port}");

        server.listen(handleRequest);
      });

      return _commandCompleter.future;
    });
  }

  /// Parses the `--port` command-line argument and exits if it isn't valid.
  int parsePort() {
    try {
      return int.parse(commandOptions['port']);
    } on FormatException catch(_) {
      log.error('Could not parse port "${commandOptions['port']}"');
      this.printUsage();
      exit(exit_codes.USAGE);
    }
  }

  /// Installs dependencies is the lockfile is out of date with respect to the
  /// pubspec.
  Future ensureLockFileIsUpToDate() {
    return new Future.sync(() {
      // The server relies on an up-to-date lockfile, so install first if
      // needed.
      if (!entrypoint.isLockFileUpToDate()) {
        log.message("Dependencies have changed, installing...");
        return entrypoint.installDependencies().then((_) {
          log.message("Dependencies installed!");
        });
      }
    });
  }

  void handleRequest(HttpRequest request) {
    var id = getIdFromUri(request.uri);
    if (id == null) {
      notFound(request, "Path ${request.uri.path} is not valid.");
      return;
    }

    _barback.getAssetById(id).then((asset) {
      return validateStream(asset.read()).then((stream) {
        log.message(
            "$_green${request.method}$_none ${request.uri} -> $asset");
        // TODO(rnystrom): Set content-type based on asset type.
        return request.response.addStream(stream).then((_) {
          request.response.close();
        });
      }).catchError((error) {
        log.error("$_red${request.method}$_none "
            "${request.uri} -> $error");

        // If we couldn't read the asset, handle the error gracefully.
        if (error is FileException) {
          // Assume this means the asset was a file-backed source asset
          // and we couldn't read it, so treat it like a missing asset.
          notFound(request, error);
          return;
        }

        // Otherwise, it's some internal error.
        request.response.statusCode = 500;
        request.response.reasonPhrase = "Internal Error";
        request.response.write(error);
        request.response.close();
      });
    }).catchError((error) {
      log.error("$_red${request.method}$_none ${request.uri} -> $error");
      if (error is! AssetNotFoundException) {
        _commandCompleter.completeError(error);
        return;
      }

      notFound(request, error);
    });
  }

  /// Responds to [request] with a 404 response and closes it.
  void notFound(HttpRequest request, message) {
    request.response.statusCode = 404;
    request.response.reasonPhrase = "Not Found";
    request.response.write(message);
    request.response.close();
  }

  AssetId getIdFromUri(Uri uri) {
    var parts = path.url.split(uri.path);

    // Strip the leading "/" from the URL.
    parts.removeAt(0);

    var isSpecial = false;

    // Checks to see if [uri]'s path contains a special directory [name] that
    // identifies an asset within some package. If so, maps the package name
    // and path following that to be within [dir] inside that package.
    AssetId _trySpecialUrl(String name, String dir) {
      // Find the package name and the relative path in the package.
      var index = parts.indexOf(name);
      if (index == -1) return null;

      // If we got here, the path *did* contain the special directory, which
      // means we should not interpret it as a regular path, even if it's
      // missing the package name after it, which makes it invalid here.
      isSpecial = true;
      if (index + 1 >= parts.length) return null;

      var package = parts[index + 1];
      var assetPath = path.url.join(dir,
          path.url.joinAll(parts.skip(index + 2)));
      return new AssetId(package, assetPath);
    }

    // See if it's "packages" URL.
    var id = _trySpecialUrl("packages", "lib");
    if (id != null) return id;

    // See if it's an "assets" URL.
    id = _trySpecialUrl("assets", "asset");
    if (id != null) return id;

    // If we got here, we had a path like "/packages" which is a special
    // directory, but not a valid path since it lacks a following package name.
    if (isSpecial) return null;

    // Otherwise, it's a path in current package's web directory.
    return new AssetId(entrypoint.root.name,
        path.url.join("web", path.url.joinAll(parts)));
  }

  /// Creates the [Barback] instance and listens to its outputs.
  void initBarback() {
    assert(_provider != null);

    _barback = new Barback(_provider);

    _barback.results.listen((result) {
      if (result.succeeded) {
        // TODO(rnystrom): Report using growl/inotify-send where available.
        log.message("Build completed ${_green}successfully$_none");
      } else {
        log.message("Build completed with "
            "${_red}${result.errors.length}$_none errors.");
      }
    });

    _barback.errors.listen((error) {
      log.error("${_red}Build error:\n$error$_none");
    });
  }

  /// Adds all of the source assets in the provided packages to barback and
  /// then watches the public directories for changes.
  void watchSources() {
    assert(_provider != null);
    assert(_barback != null);

    for (var package in _provider.packages) {
      // Add the initial sources.
      _barback.updateSources(listAssets(package));

      // Watch the visible package directories for changes.
      var packageDir = _provider.getPackageDir(package);

      for (var name in getPublicDirectories(package)) {
        var subdirectory = path.join(packageDir, name);
        var watcher = new DirectoryWatcher(subdirectory);
        watcher.events.listen((event) {
          var id = pathToAssetId(package, packageDir, event.path);
          if (event.type == ChangeType.REMOVE) {
            _barback.removeSources([id]);
          } else {
            _barback.updateSources([id]);
          }
        });
      }
    }
  }

  /// Lists all of the visible files in [package].
  ///
  /// This is the recursive contents of the "asset" and "lib" directories (if
  /// present). If [package] is the entrypoint package, it also includes the
  /// contents of "web".
  List<AssetId> listAssets(String package) {
    var files = <AssetId>[];

    for (var dirPath in getPublicDirectories(package)) {
      var packageDir = _provider.getPackageDir(package);
      var dir = path.join(packageDir, dirPath);
      if (!dirExists(dir)) continue;
      for (var entry in listDir(dir, recursive: true)) {
        // Ignore "packages" symlinks if there.
        if (path.split(entry).contains("packages")) continue;

        // Skip directories.
        if (!fileExists(entry)) continue;

        files.add(pathToAssetId(package, packageDir, entry));
      }
    }

    return files;
  }

  /// Gets the names of the top-level directories in [package] whose contents
  /// should be provided as source assets.
  Iterable<String> getPublicDirectories(String package) {
    var directories = ["asset", "lib"];
    if (package == entrypoint.root.name) directories.add("web");
    return directories;
  }

  /// Converts a local file path to an [AssetId].
  AssetId pathToAssetId(String package, String packageDir, String filePath) {
    var relative = path.relative(filePath, from: packageDir);

    // AssetId paths use "/" on all platforms.
    relative = path.toUri(relative).path;

    return new AssetId(package, relative);
  }
}
