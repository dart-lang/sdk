// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.build;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import '../barback/dart2js_transformer.dart';
import '../barback.dart' as barback;
import '../command.dart';
import '../exit_codes.dart' as exit_codes;
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

  Future onRun() {
    if (!dirExists(source)) {
      throw new ApplicationException("There is no '$source' directory.");
    }

    cleanDir(target);

    var dart2jsTransformer;

    return entrypoint.ensureLockFileIsUpToDate().then((_) {
      return entrypoint.loadPackageGraph();
    }).then((graph) {
      dart2jsTransformer = new Dart2JSTransformer(graph);

      // Since this server will only be hit by the transformer loader and isn't
      // user-facing, just use an IPv4 address to avoid a weird bug on the
      // OS X buildbots.
      return barback.createServer("127.0.0.1", 0, graph,
          builtInTransformers: [dart2jsTransformer],
          watchForUpdates: false);
    }).then((server) {
      // Show in-progress errors, but not results. Those get handled implicitly
      // by getAllAssets().
      server.barback.errors.listen((error) {
        log.error(log.red("Build error:\n$error"));
      });

      return log.progress("Building ${entrypoint.root.name}",
          () => server.barback.getAllAssets());
    }).then((assets) {
      // Don't copy Dart libraries. Their contents will already be included
      // in the generated JavaScript.
      assets = assets.where((asset) => asset.id.extension != ".dart");

      return Future.wait(assets.map((asset) {
        // Figure out the output directory for the asset, which is the same
        // as the path pub serve would use to serve it.
        var relativeUrl = barback.idtoUrlPath(entrypoint.root.name, asset.id);

        // Remove the leading "/".
        relativeUrl = relativeUrl.substring(1);

        var relativePath = path.fromUri(new Uri(path: relativeUrl));
        var destPath = path.join(target, relativePath);

        ensureDir(path.dirname(destPath));
        // TODO(rnystrom): Should we display this to the user?
        return createFileFromStream(asset.read(), destPath);
      })).then((_) {
        _copyBrowserJsFiles(dart2jsTransformer.entrypoints);
        // TODO(rnystrom): Should this count include the JS files?
        log.message("Built ${assets.length} files!");
      });
    }).catchError((error) {
      // If [getAllAssets()] throws a BarbackException, the error has already
      // been reported.
      if (error is! BarbackException) throw error;

      log.error(log.red("Build failed."));
      return flushThenExit(exit_codes.DATA);
    });
  }

  /// If this package depends directly on the `browser` package, this ensures
  /// that the JavaScript bootstrap files are copied into `packages/browser/`
  /// directories next to each entrypoint in [entrypoints].
  void _copyBrowserJsFiles(Iterable<AssetId> entrypoints) {
    // Must depend on the browser package.
    if (!entrypoint.root.dependencies.any(
        (dep) => dep.name == 'browser' && dep.source == 'hosted')) {
      return;
    }

    // Get all of the directories that contain Dart entrypoints.
    var entrypointDirs = entrypoints
        .map((id) => path.url.split(id.path))
        .map((parts) => parts.skip(1)) // Remove "web/".
        .map((relative) => path.dirname(path.joinAll(relative)))
        .toSet();

    for (var dir in entrypointDirs) {
      // TODO(nweiz): we should put browser JS files next to any HTML file
      // rather than any entrypoint. An HTML file could import an entrypoint
      // that's not adjacent.
      _addBrowserJs(dir, "dart");
      _addBrowserJs(dir, "interop");
    }
  }

  // TODO(nweiz): do something more principled when issue 6101 is fixed.
  /// Ensures that the [name].js file is copied into [directory] in [target],
  /// under `packages/browser/`.
  void _addBrowserJs(String directory, String name) {
    var jsPath = path.join(
        target, directory, 'packages', 'browser', '$name.js');
    ensureDir(path.dirname(jsPath));
    copyFile(path.join(entrypoint.packagesDir, 'browser', '$name.js'), jsPath);
  }
}
