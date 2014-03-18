// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.build;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import '../barback/build_environment.dart';
import '../command.dart';
import '../exit_codes.dart' as exit_codes;
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';

final _arrow = getSpecial('\u2192', '=>');

/// The set of top level directories in the entrypoint package that can be
/// built.
final _allowedBuildDirectories = new Set<String>.from([
  "benchmark", "bin", "example", "test", "web"
]);

/// Handles the `build` pub command.
class BuildCommand extends PubCommand {
  String get description => "Apply transformers to build a package.";
  String get usage => "pub build [options] [directories...]";
  List<String> get aliases => const ["deploy", "settle-up"];
  bool get takesArguments => true;

  // TODO(nweiz): make this configurable.
  /// The path to the application's build output directory.
  String get target => 'build';

  /// The build mode.
  BarbackMode get mode => new BarbackMode(commandOptions["mode"]);

  /// The number of files that have been built and written to disc so far.
  int builtFiles = 0;

  /// The names of the top-level build directories that will be built.
  final buildDirectories = new Set<String>();

  BuildCommand() {
    commandParser.addOption("format",
        help: "How output should be displayed.",
        allowed: ["text", "json"], defaultsTo: "text");

    commandParser.addOption("mode", defaultsTo: BarbackMode.RELEASE.toString(),
        help: "Mode to run transformers in.");

    commandParser.addFlag("all", help: "Build all buildable directories.",
        defaultsTo: false, negatable: false);
  }

  Future onRun() {
    log.json.enabled = commandOptions["format"] == "json";

    _parseBuildDirectories();
    cleanDir(target);

    var environment;
    var errorsJson = [];
    var logJson = [];

    // Since this server will only be hit by the transformer loader and isn't
    // user-facing, just use an IPv4 address to avoid a weird bug on the
    // OS X buildbots.
    return BuildEnvironment.create(entrypoint, "127.0.0.1", 0, mode,
        WatcherType.NONE, useDart2JS: true)
          .then((env) {
      environment = env;

      // Register all of the build directories.
      // TODO(rnystrom): We don't actually need to bind servers for these, we
      // just need to add them to barback's sources. Add support to
      // BuildEnvironment for going the latter without the former.
      return Future.wait(buildDirectories.map(
          (dir) => environment.serveDirectory(dir)));
    }).then((_) {
      // Show in-progress errors, but not results. Those get handled implicitly
      // by getAllAssets().
      environment.barback.errors.listen((error) {
        log.error(log.red("Build error:\n$error"));

        if (log.json.enabled) {
          // Wrap the error in a map in case we end up decorating it with more
          // properties later.
          errorsJson.add({
            "error": error.toString()
          });
        }
      });

      // If we're using JSON output, the regular server logging is disabled.
      // Instead, we collect it here to include in the final JSON result.
      if (log.json.enabled) {
        environment.barback.log.listen(
            (entry) => logJson.add(_logEntryToJson(entry)));
      }

      return log.progress("Building ${entrypoint.root.name}",
          () => environment.barback.getAllAssets()).then((assets) {
        // Find all of the JS entrypoints we built.
        var dart2JSEntrypoints = assets
            .where((asset) => asset.id.path.endsWith(".dart.js"))
            .map((asset) => asset.id);

        return Future.wait(assets.map(_writeAsset)).then((_) {
          builtFiles += _copyBrowserJsFiles(dart2JSEntrypoints);
          log.message('Built $builtFiles ${pluralize('file', builtFiles)} '
              'to "$target".');

          log.json.message({
            "buildResult": "success",
            "outputDirectory": target,
            "numFiles": builtFiles,
            "log": logJson
          });
        });
      });
    }).catchError((error) {
      // If [getAllAssets()] throws a BarbackException, the error has already
      // been reported.
      if (error is! BarbackException) throw error;

      log.error(log.red("Build failed."));
      log.json.message({
        "buildResult": "failure",
        "errors": errorsJson,
        "log": logJson
      });

      return flushThenExit(exit_codes.DATA);
    });
  }

  /// Parses the command-line arguments to determine the set of top-level
  /// directories to build.
  ///
  /// If there are no arguments to `pub build`, this will just be "web".
  ///
  /// If the `--all` flag is set, then it will be all buildable directories
  /// that exist.
  ///
  /// Otherwise, all arguments should be the names of directories to include.
  ///
  /// Throws an exception if the arguments are invalid.
  void _parseBuildDirectories() {
    if (commandOptions["all"]) {
      if (commandOptions.rest.isNotEmpty) {
        usageError(
            'Build directory names are not allowed if "--all" is passed.');
      }

      // Include every build directory that exists in the package.
      var allowed = _allowedBuildDirectories.where(
          (d) => dirExists(path.join(entrypoint.root.dir, d)));

      if (allowed.isEmpty) {
        var buildDirs = toSentence(ordered(_allowedBuildDirectories.map(
            (name) => '"$name"')));
        dataError('There are no buildable directories.\n'
                  'The supported directories are $buildDirs.');
      }

      buildDirectories.addAll(allowed);
      return;
    }

    buildDirectories.addAll(commandOptions.rest);

    // If no directory were specified, default to "web".
    if (buildDirectories.isEmpty) {
      buildDirectories.add("web");
    }

    // Make sure the arguments are known directories.
    var disallowed = buildDirectories.where(
        (dir) => !_allowedBuildDirectories.contains(dir));
    if (disallowed.isNotEmpty) {
      var dirs = pluralize("directory", disallowed.length,
          plural: "directories");
      var names = toSentence(ordered(disallowed).map((name) => '"$name"'));
      var allowed = toSentence(ordered(_allowedBuildDirectories.map(
          (name) => '"$name"')));
      usageError('Unsupported build $dirs $names.\n'
                 'The allowed directories are $allowed.');
    }

    // Make sure all of the build directories exist.
    var missing = buildDirectories.where(
        (dir) => !dirExists(path.join(entrypoint.root.dir, dir)));

    if (missing.length == 1) {
      dataError('Directory "${missing.single}" does not exist.');
    } else if (missing.isNotEmpty) {
      var names = toSentence(ordered(missing).map((name) => '"$name"'));
      dataError('Directories $names do not exist.');
    }
  }

  /// Writes [asset] to the appropriate build directory.
  ///
  /// If [asset] is in the special "assets" directory, writes it to every
  /// build directory.
  Future _writeAsset(Asset asset) {
    // In release mode, strip out .dart files since all relevant ones have been
    // compiled to JavaScript already.
    if (mode == BarbackMode.RELEASE && asset.id.extension == ".dart") {
      return new Future.value();
    }

    var destPath = _idtoPath(asset.id);

    // If the asset is from a public directory, copy it into all of the
    // top-level build directories.
    if (path.isWithin("assets", destPath) ||
        path.isWithin("packages", destPath)) {
      return Future.wait(buildDirectories.map((buildDir) =>
          _writeOutputFile(asset, path.join(buildDir, destPath))));
    }

    return _writeOutputFile(asset, destPath);
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
  ///     foo|asset/foo.png      -> assets/foo/foo.png
  ///     myapp|test/main.dart   -> test/main.dart
  ///     foo|test/main.dart     -> ERROR
  ///
  /// Throws a [FormatException] if [id] is not a valid public asset.
  String _idtoPath(AssetId id) {
    var parts = path.url.split(id.path);

    if (parts.length < 2) {
      throw new FormatException(
          "Can not build assets from top-level directory.");
    }

    // Map "asset" and "lib" to their shared directories.
    var dir = parts[0];
    var rest = parts.skip(1);

    if (dir == "asset") {
      return path.join("assets", id.package, path.joinAll(rest));
    }

    if (dir == "lib") {
      return path.join("packages", id.package, path.joinAll(rest));
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
    var destPath = path.join(target, relativePath);
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
    var entrypointDirs = entrypoints
        // Convert the asset path to a native-separated one and get the
        // directory containing the entrypoint.
        .map((id) => path.dirname(path.joinAll(path.url.split(id.path))))
        // Don't copy files to the top levels of the build directories since
        // the normal lib asset copying will take care of that.
        .where((dir) => dir.contains(path.separator))
        .toSet();

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
    var jsPath = path.join(entrypoint.root.dir,
        target, directory, 'packages', 'browser', '$name.js');
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
