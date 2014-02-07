// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.build;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import '../barback/build_environment.dart';
import '../barback.dart' as barback;
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
  String get usage => "pub build [options]";
  List<String> get aliases => const ["deploy", "settle-up"];
  bool get takesArguments => true;

  // TODO(nweiz): make this configurable.
  /// The path to the application's build output directory.
  String get target => path.join(entrypoint.root.dir, 'build');

  /// The build mode.
  BarbackMode get mode => new BarbackMode(commandOptions['mode']);

  /// The number of files that have been built and written to disc so far.
  int builtFiles = 0;

  /// The names of the top-level build directories that will be built.
  final buildDirectories = new Set<String>();

  BuildCommand() {
    commandParser.addOption('mode', defaultsTo: BarbackMode.RELEASE.toString(),
        help: 'Mode to run transformers in.');

    commandParser.addFlag('all', help: "Build all buildable directories.",
        defaultsTo: false, negatable: false);
  }

  Future onRun() {
    var exitCode = _parseBuildDirectories();
    if (exitCode != exit_codes.SUCCESS) return flushThenExit(exitCode);

    cleanDir(target);

    // Since this server will only be hit by the transformer loader and isn't
    // user-facing, just use an IPv4 address to avoid a weird bug on the
    // OS X buildbots.
    return BuildEnvironment.create(entrypoint, "127.0.0.1", 0, mode,
        WatcherType.NONE, buildDirectories, useDart2JS: true)
          .then((environment) {

      // Show in-progress errors, but not results. Those get handled implicitly
      // by getAllAssets().
      environment.server.barback.errors.listen((error) {
        log.error(log.red("Build error:\n$error"));
      });

      return log.progress("Building ${entrypoint.root.name}",
          () => environment.server.barback.getAllAssets()).then((assets) {
        // Find all of the JS entrypoints we built.
        var dart2JSEntrypoints = assets
            .where((asset) => asset.id.path.endsWith(".dart.js"))
            .map((asset) => asset.id);

        return Future.wait(assets.map(_writeAsset)).then((_) {
          builtFiles += _copyBrowserJsFiles(dart2JSEntrypoints);
          log.message("Built $builtFiles ${pluralize('file', builtFiles)}!");
        });
      });
    }).catchError((error) {
      // If [getAllAssets()] throws a BarbackException, the error has already
      // been reported.
      if (error is! BarbackException) throw error;

      log.error(log.red("Build failed."));
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
  /// Returns the exit code of an error, or zero if it parsed correctly.
  int _parseBuildDirectories() {
    if (commandOptions["all"]) {
      if (commandOptions.rest.isNotEmpty) {
        log.error(
            'Build directory names are not allowed if "--all" is passed.');
        return exit_codes.USAGE;
      }

      // Include every build directory that exists in the package.
      var allowed = _allowedBuildDirectories.where(
          (d) => dirExists(path.join(entrypoint.root.dir, d)));

      if (allowed.isEmpty) {
        var buildDirs = toSentence(ordered(_allowedBuildDirectories.map(
            (name) => '"$name"')));
        log.error('There are no buildable directories.\n'
                  'The supported directories are $buildDirs.');
        return exit_codes.DATA;
      }

      buildDirectories.addAll(allowed);
      return exit_codes.SUCCESS;
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
      log.error('Unsupported build $dirs $names.\n'
                'The allowed directories are $allowed.');
      return exit_codes.USAGE;
    }

    // Make sure all of the build directories exist.
    var missing = buildDirectories.where(
        (dir) => !dirExists(path.join(entrypoint.root.dir, dir)));

    if (missing.length == 1) {
      log.error('Directory "${missing.single}" does not exist.');
      return exit_codes.DATA;
    } else if (missing.isNotEmpty) {
      var names = toSentence(ordered(missing).map((name) => '"$name"'));
      log.error('Directories $names do not exist.');
      return exit_codes.DATA;
    }

    return exit_codes.SUCCESS;
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

    // If the asset is from a package's "lib" directory, we make it available
    // as an input for transformers, but don't want it in the final output.
    // (Any Dart code in there should be imported and compiled to JS, anything
    // else we want to omit.)
    if (asset.id.path.startsWith("lib/")) {
      return new Future.value();
    }

    // Figure out the output directory for the asset, which is the same as the
    // path pub serve would use to serve it.
    var relativeUrl = barback.idtoUrlPath(entrypoint.root.name, asset.id,
        useWebAsRoot: false);

    // Remove the leading "/".
    relativeUrl = relativeUrl.substring(1);

    // If the asset is from the shared "assets" directory, copy it into all of
    // the top-level build directories.
    if (relativeUrl.startsWith("assets/")) {
      builtFiles += buildDirectories.length;
      return Future.wait(buildDirectories.map(
          (buildDir) => _writeOutputFile(asset,
              path.url.join(buildDir, relativeUrl))));
    }

    builtFiles++;
    return _writeOutputFile(asset, relativeUrl);
  }

  /// Writes the contents of [asset] to [relativeUrl] within the build
  /// directory.
  Future _writeOutputFile(Asset asset, String relativeUrl) {
    var relativePath = path.fromUri(new Uri(path: relativeUrl));
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
    if (!entrypoint.root.dependencies.any(
        (dep) => dep.name == 'browser' && dep.source == 'hosted')) {
      return 0;
    }

    // Get all of the directories that contain Dart entrypoints.
    var entrypointDirs = entrypoints
        .map((id) => path.url.split(id.path))
        .map((relative) => path.dirname(path.joinAll(relative)))
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
    var jsPath = path.join(
        target, directory, 'packages', 'browser', '$name.js');
    ensureDir(path.dirname(jsPath));

    // TODO(rnystrom): This won't work if we get rid of symlinks and the top
    // level "packages" directory. Will need to copy from the browser
    // directory.
    copyFile(path.join(entrypoint.packagesDir, 'browser', '$name.js'), jsPath);
  }
}
