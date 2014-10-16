// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.build;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import '../barback/asset_environment.dart';
import '../exit_codes.dart' as exit_codes;
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';
import 'barback.dart';

final _arrow = getSpecial('\u2192', '=>');

/// Handles the `build` pub command.
class BuildCommand extends BarbackCommand {
  String get description => "Apply transformers to build a package.";
  String get usage => "pub build [options] [directories...]";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-build.html";
  List<String> get aliases => const ["deploy", "settle-up"];

  /// The path to the application's build output directory.
  String get outputDirectory => commandOptions["output"];

  List<String> get defaultSourceDirectories => ["web"];

  /// The number of files that have been built and written to disc so far.
  int builtFiles = 0;

  BuildCommand() {
    commandParser.addOption(
        "format",
        help: "How output should be displayed.",
        allowed: ["text", "json"],
        defaultsTo: "text");

    commandParser.addOption(
        "output",
        abbr: "o",
        help: "Directory to write build outputs to.",
        defaultsTo: "build");
  }

  Future onRunTransformerCommand() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        cleanDir(outputDirectory);
        var errorsJson = [];
        var logJson = [];
        completer0.complete(
            AssetEnvironment.create(
                entrypoint,
                mode,
                useDart2JS: true).then(((environment) {
          environment.barback.errors.listen((error) {
            log.error(log.red("Build error:\n$error"));
            if (log.json.enabled) {
              errorsJson.add({
                "error": error.toString()
              });
            }
          });
          if (log.json.enabled) {
            environment.barback.log.listen(
                (entry) => logJson.add(_logEntryToJson(entry)));
          }
          return log.progress("Building ${entrypoint.root.name}", () {
            return Future.wait(
                sourceDirectories.map((dir) => environment.serveDirectory(dir))).then((_) {
              return environment.barback.getAllAssets();
            });
          }).then((assets) {
            var dart2JSEntrypoints = assets.where(
                (asset) => asset.id.path.endsWith(".dart.js")).map((asset) => asset.id);
            return Future.wait(assets.map(_writeAsset)).then((_) {
              builtFiles += _copyBrowserJsFiles(dart2JSEntrypoints);
              log.message(
                  'Built $builtFiles ${pluralize('file', builtFiles)} ' 'to "$outputDirectory".');
              log.json.message({
                "buildResult": "success",
                "outputDirectory": outputDirectory,
                "numFiles": builtFiles,
                "log": logJson
              });
            });
          });
        })).catchError(((error) {
          if (error is! BarbackException) throw error;
          log.error(log.red("Build failed."));
          log.json.message({
            "buildResult": "failure",
            "errors": errorsJson,
            "log": logJson
          });
          return flushThenExit(exit_codes.DATA);
        })));
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }

  /// Writes [asset] to the appropriate build directory.
  ///
  /// If [asset] is in the special "packages" directory, writes it to every
  /// build directory.
  Future _writeAsset(Asset asset) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        join0() {
          var destPath = _idToPath(asset.id);
          join1() {
            completer0.complete(_writeOutputFile(asset, destPath));
          }
          if (path.isWithin("packages", destPath)) {
            completer0.complete(Future.wait(sourceDirectories.map(((buildDir) {
              return _writeOutputFile(asset, path.join(buildDir, destPath));
            }))));
          } else {
            join1();
          }
        }
        if (mode == BarbackMode.RELEASE && asset.id.extension == ".dart") {
          completer0.complete(null);
        } else {
          join0();
        }
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }

  /// Converts [id] to a relative path in the output directory for that asset.
  ///
  /// This corresponds to the URL that could be used to request that asset from
  /// pub serve.
  ///
  /// Examples (where entrypoint is "myapp"):
  ///
  ///     myapp|web/index.html   -> web/index.html
  ///     myapp|lib/lib.dart     -> packages/myapp/lib.dart
  ///     foo|lib/foo.dart       -> packages/foo/foo.dart
  ///     myapp|test/main.dart   -> test/main.dart
  ///     foo|test/main.dart     -> ERROR
  ///
  /// Throws a [FormatException] if [id] is not a valid public asset.
  String _idToPath(AssetId id) {
    var parts = path.split(path.fromUri(id.path));

    if (parts.length < 2) {
      throw new FormatException(
          "Can not build assets from top-level directory.");
    }

    // Map "lib" to the "packages" directory.
    if (parts[0] == "lib") {
      return path.join("packages", id.package, path.joinAll(parts.skip(1)));
    }

    // Shouldn't be trying to access non-public directories of other packages.
    assert(id.package == entrypoint.root.name);

    // Allow any path in the entrypoint package.
    return path.joinAll(parts);
  }

  /// Writes the contents of [asset] to [relativePath] within the build
  /// directory.
  Future _writeOutputFile(Asset asset, String relativePath) {
    builtFiles++;
    var destPath = path.join(outputDirectory, relativePath);
    ensureDir(path.dirname(destPath));
    return createFileFromStream(asset.read(), destPath);
  }

  /// If this package depends directly on the `browser` package, this ensures
  /// that the JavaScript bootstrap files are copied into `packages/browser/`
  /// directories next to each entrypoint in [entrypoints].
  ///
  /// Returns the number of files it copied.
  int _copyBrowserJsFiles(Iterable<AssetId> entrypoints) {
    // Must depend on the browser package.
    if (!entrypoint.root.immediateDependencies.any(
        (dep) => dep.name == 'browser' && dep.source == 'hosted')) {
      return 0;
    }

    // Get all of the subdirectories that contain Dart entrypoints.
    var entrypointDirs =
        entrypoints// Convert the asset path to a native-separated one and get the
    // directory containing the entrypoint.
    .map(
        (id) =>
            path.dirname(
                path.fromUri(
                    id.path)))// Don't copy files to the top levels of the build directories since
    // the normal lib asset copying will take care of that.
    .where((dir) => path.split(dir).length > 1).toSet();

    for (var dir in entrypointDirs) {
      // TODO(nweiz): we should put browser JS files next to any HTML file
      // rather than any entrypoint. An HTML file could import an entrypoint
      // that's not adjacent.
      _addBrowserJs(dir, "dart");
      _addBrowserJs(dir, "interop");
    }

    return entrypointDirs.length * 2;
  }

  // TODO(nweiz): do something more principled when issue 6101 is fixed.
  /// Ensures that the [name].js file is copied into [directory] in [target],
  /// under `packages/browser/`.
  void _addBrowserJs(String directory, String name) {
    var jsPath = entrypoint.root.path(
        outputDirectory,
        directory,
        'packages',
        'browser',
        '$name.js');
    ensureDir(path.dirname(jsPath));

    // TODO(rnystrom): This won't work if we get rid of symlinks and the top
    // level "packages" directory. Will need to copy from the browser
    // directory.
    copyFile(path.join(entrypoint.packagesDir, 'browser', '$name.js'), jsPath);
  }

  /// Converts [entry] to a JSON object for use with JSON-formatted output.
  Map _logEntryToJson(LogEntry entry) {
    var data = {
      "level": entry.level.name,
      "transformer": {
        "name": entry.transform.transformer.toString(),
        "primaryInput": {
          "package": entry.transform.primaryId.package,
          "path": entry.transform.primaryId.path
        },
      },
      "assetId": {
        "package": entry.assetId.package,
        "path": entry.assetId.path
      },
      "message": entry.message
    };

    if (entry.span != null) {
      data["span"] = {
        "url": entry.span.sourceUrl,
        "start": {
          "line": entry.span.start.line,
          "column": entry.span.start.column
        },
        "end": {
          "line": entry.span.end.line,
          "column": entry.span.end.column
        },
      };
    }

    return data;
  }
}
