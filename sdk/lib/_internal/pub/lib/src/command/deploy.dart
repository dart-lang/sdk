// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.deploy;

import 'dart:async';
import 'dart:math' as math;

import 'package:analyzer_experimental/analyzer.dart';
import 'package:pathos/path.dart' as path;

import '../command.dart';
import '../dart.dart' as dart;
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';

final _arrow = getSpecial('\u2192', '=>');

/// Handles the `deploy` pub command.
class DeployCommand extends PubCommand {
  final description = "Copy and compile all Dart entrypoints in the 'web' "
      "directory.";
  final usage = "pub deploy [options]";
  final aliases = const ["settle-up"];

  // TODO(nweiz): make these configurable.
  /// The path to the source directory of the deployment.
  String get source => path.join(entrypoint.root.dir, 'web');

  /// The path to the target directory of the deployment.
  String get target => path.join(entrypoint.root.dir, 'deploy');

  /// The set of Dart entrypoints in [source] that should be compiled to [out].
  final _entrypoints = new List<String>();

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
          // TODO(nweiz): we should put dart.js files next to any HTML file
          // rather than any entrypoint. An HTML file could import an entrypoint
          // that's not adjacent.
          _maybeAddDartJs(path.dirname(targetFile));
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
  /// the deploy command so we know how much padding to add when printing them.
  /// This should only be run after [_findEntrypoints].
  void _computeLogSize() {
    _maxVerbLength = ["Copying", "Compiling"]
        .map((verb) => verb.length).reduce(math.max);
    var sourceLengths = new List.from(
            _entrypoints.map((file) => path.relative(file).length))
        ..add("${path.relative(source)}${path.separator}".length);
    if (_shouldAddDartJs) sourceLengths.add("package:browser/dart.js".length);
    _maxSourceLength = sourceLengths.reduce(math.max);
  }

  /// Log a deployment action. This should only be run after [_computeLogSize].
  void _logAction(String verb, String source, String target) {
    verb = padRight(verb, _maxVerbLength);
    source = padRight(source, _maxSourceLength);
    log.message("$verb $source $_arrow $target");
  }

  // TODO(nweiz): do something more principled when issue 6101 is fixed.
  /// If this package depends non-transitively on the `browser` package, this
  /// ensures that the `dart.js` file is copied into [directory], under
  /// `packages/browser/`.
  void _maybeAddDartJs(String directory) {
    var jsPath = path.join(directory, 'packages', 'browser', 'dart.js');
    // TODO(nweiz): warn if they don't depend on browser?
    if (!_shouldAddDartJs || fileExists(jsPath)) return;

    _logAction("Copying", "package:browser/dart.js", path.relative(jsPath));
    ensureDir(path.dirname(jsPath));
    copyFile(path.join(entrypoint.packagesDir, 'browser', 'dart.js'), jsPath);
  }

  /// Whether we should copy the browser package's dart.js file into the
  /// deployed app.
  bool get _shouldAddDartJs {
    return !_entrypoints.isEmpty &&
        entrypoint.root.dependencies.any((dep) =>
            dep.name == 'browser' && dep.source == 'hosted');
  }
}
