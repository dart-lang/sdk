// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.build;

import 'dart:async';
import 'dart:math' as math;

import 'package:analyzer_experimental/analyzer.dart';
import 'package:path/path.dart' as path;

import '../command.dart';
import '../dart.dart' as dart;
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';

final _arrow = getSpecial('\u2192', '=>');

/// Handles the `build` pub command.
class BuildCommand extends PubCommand {
  final description = "Copy and compile all Dart entrypoints in the 'web' "
      "directory.";
  final usage = "pub build [options]";
  final aliases = const ["deploy", "settle-up"];

  // TODO(nweiz): make these configurable.
  /// The path to the source directory of the application.
  String get source => path.join(entrypoint.root.dir, 'web');

  /// The path to the application's build output directory.
  String get target => path.join(entrypoint.root.dir, 'build');

  /// The set of Dart entrypoints in [source] that should be compiled to
  /// [target].
  final _entrypoints = <String>[];

  int _maxVerbLength;
  int _maxSourceLength;

  Future onRun() {
    if (!dirExists(source)) {
      throw new ApplicationException("There is no '$source' directory.");
    }

    return entrypoint.packageFiles(beneath: source).then((files) {
      log.message("Finding entrypoints...");
      _findEntrypoints(files);
      _computeLogSize();

      cleanDir(target);
      _logAction("Copying", "${path.relative(source)}${path.separator}",
          "${path.relative(target)}${path.separator}");
      copyFiles(files.where((file) => path.extension(file) != '.dart'),
          source, target);

      return Future.forEach(_entrypoints, (sourceFile) {
        var targetFile =
            path.join(target, path.relative(sourceFile, from: source));
        var relativeTargetFile = path.relative(targetFile);
        var relativeSourceFile = path.relative(sourceFile);

        ensureDir(path.dirname(targetFile));
        _logAction("Compiling", relativeSourceFile, "$relativeTargetFile.js");
        // TODO(nweiz): print dart2js errors/warnings in red.
        return dart.compile(sourceFile, packageRoot: entrypoint.packagesDir)
            .then((js) {
          writeTextFile("$targetFile.js", js, dontLogContents: true);
          _logAction("Compiling", relativeSourceFile, "$relativeTargetFile");
          return dart.compile(sourceFile,
              packageRoot: entrypoint.packagesDir, toDart: true);
        }).then((dart) {
          writeTextFile(targetFile, dart, dontLogContents: true);
          // TODO(nweiz): we should put browser JS files next to any HTML file
          // rather than any entrypoint. An HTML file could import an entrypoint
          // that's not adjacent.
          _maybeAddBrowserJs(path.dirname(targetFile), "dart");
          _maybeAddBrowserJs(path.dirname(targetFile), "interop");
        });
      });
    });
  }

  /// Populates [_entrypoints] with all of the Dart entrypoints in [files].
  /// [files] should be a list of paths in [source].
  void _findEntrypoints(List<String> files) {
    for (var file in files) {
      if (path.extension(file) != '.dart') continue;
      try {
        if (!dart.isEntrypoint(parseDartFile(file))) continue;
      } on AnalyzerErrorGroup catch (e) {
        log.warning(e.message);
        continue;
      }
      _entrypoints.add(file);
    }
    // Sort to ensure a deterministic order of compilation and output.
    _entrypoints.sort();
  }

  /// Computes the maximum widths of words that will be used in log output for
  /// the build command so we know how much padding to add when printing them.
  /// This should only be run after [_findEntrypoints].
  void _computeLogSize() {
    _maxVerbLength = ["Copying", "Compiling"]
        .map((verb) => verb.length).reduce(math.max);
    var sourceLengths = new List.from(
            _entrypoints.map((file) => path.relative(file).length))
        ..add("${path.relative(source)}${path.separator}".length);
    if (_shouldAddBrowserJs) {
      sourceLengths.add("package:browser/interop.js".length);
    }
    _maxSourceLength = sourceLengths.reduce(math.max);
  }

  /// Log a build action. This should only be run after [_computeLogSize].
  void _logAction(String verb, String source, String target) {
    verb = padRight(verb, _maxVerbLength);
    source = padRight(source, _maxSourceLength);
    log.message("$verb $source $_arrow $target");
  }

  // TODO(nweiz): do something more principled when issue 6101 is fixed.
  /// If this package depends non-transitively on the `browser` package, this
  /// ensures that the [name].js file is copied into [directory], under
  /// `packages/browser/`.
  void _maybeAddBrowserJs(String directory, String name) {
    var jsPath = path.join(directory, 'packages', 'browser', '$name.js');
    // TODO(nweiz): warn if they don't depend on browser?
    if (!_shouldAddBrowserJs || fileExists(jsPath)) return;

    _logAction("Copying", "package:browser/$name.js", path.relative(jsPath));
    ensureDir(path.dirname(jsPath));
    copyFile(path.join(entrypoint.packagesDir, 'browser', '$name.js'), jsPath);
  }

  /// Whether we should copy the browser package's JS files into the built app.
  bool get _shouldAddBrowserJs {
    return !_entrypoints.isEmpty &&
        entrypoint.root.dependencies.any((dep) =>
            dep.name == 'browser' && dep.source == 'hosted');
  }
}
