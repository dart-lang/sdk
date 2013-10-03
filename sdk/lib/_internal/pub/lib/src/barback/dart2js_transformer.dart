// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.dart2js_transformer;

import 'dart:async';
import 'dart:io';

import 'package:analyzer_experimental/analyzer.dart';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import '../../../../compiler/implementation/source_file_provider.dart'
    show SourceFileProvider;
import '../../../../compiler/implementation/source_file.dart';
import '../barback.dart';
import '../dart.dart' as dart;
import '../io.dart';
import '../package.dart';
import '../package_graph.dart';

/// A [Transformer] that uses dart2js's library API to transform Dart
/// entrypoints in "web" to JavaScript.
class Dart2JSTransformer extends Transformer {
  final PackageGraph _graph;

  Dart2JSTransformer(this._graph);

  /// Only ".dart" files within "web/" are processed.
  Future<bool> isPrimary(Asset asset) {
    return new Future.value(
        asset.id.extension == ".dart" &&
        asset.id.path.startsWith("web/"));
  }

  Future apply(Transform transform) {
    var stopwatch = new Stopwatch();
    stopwatch.start();

    return transform.primaryInput.readAsString().then((code) {
      try {
        if (!dart.isEntrypoint(parseCompilationUnit(code))) return;
      } on AnalyzerErrorGroup catch (e) {
        transform.logger.error(e.message);
        return;
      }

      var provider = new _BarbackSourceFileProvider(_graph, transform);

      // Create a "path" to the entrypoint script. The entrypoint may not
      // actually be on disk, but this gives dart2js a root to resolve
      // relative paths against.
      var id = transform.primaryInput.id;
      var entrypoint = path.url.join(
          path.toUri(_graph.packages[id.package].dir).path,
          id.path);

      var packageRoot = path.join(_graph.entrypoint.root.dir, "packages");

      // TODO(rnystrom): Should have more sophisticated error-handling here.
      // Need to report compile errors to the user in an easily visible way.
      // Need to make sure paths in errors are mapped to the original source
      // path so they can understand them.
      return dart.compile(entrypoint,
          packageRoot: packageRoot, provider: provider).then((js) {
        var id = transform.primaryInput.id.changeExtension(".dart.js");
        transform.addOutput(new Asset.fromString(id, js));

        stopwatch.stop();
        transform.logger.info("Generated $id (${js.length} characters) in "
            "${stopwatch.elapsed}");
      });
    });
  }
}

/// A [SourceFileProvider] that dart2js will use to load files that are
/// produced by Barback.
class _BarbackSourceFileProvider implements SourceFileProvider {
  final PackageGraph _graph;
  final Transform _transform;

  /// The map of previously loaded files.
  ///
  /// dart2js uses this to avoid loading the same file multiple times.
  final sourceFiles = new Map<String, SourceFile>();

  _BarbackSourceFileProvider(this._graph, this._transform);

  Future<String> readStringFromUri(Uri resourceUri) {
    // We only expect to get absolute "file:" URLs from dart2js.
    assert(resourceUri.isAbsolute);
    assert(resourceUri.scheme == "file");

    var sourcePath = path.fromUri(resourceUri);
    return _readResource(resourceUri).then((source) {
      sourceFiles[resourceUri.toString()] =
          new SourceFile(path.relative(sourcePath), source);
      return source;
    });
  }

  // The default [SourceFileProvider] does this, so we'll do the same.
  Future<String> call(Uri resourceUri) => readStringFromUri(resourceUri);

  Future<String> _readResource(Uri url) {
    // See if the path is within a package. If so, use Barback so we can use
    // generated Dart assets.
    var id = _sourceUrlToId(url);
    if (id != null) return _transform.readInputAsString(id);

    // If we get here, the path doesn't appear to be in a package, so we'll
    // skip Barback and just hit the file system. This will occur at the very
    // least for dart2js's implementations of the core libraries.
    var sourcePath = path.fromUri(url);
    return new File(sourcePath).readAsString();
  }

  AssetId _sourceUrlToId(Uri url) {
    // See if it's a special path with "packages" or "assets" in it.
    var id = specialUrlToId(url);
    if (id != null) return id;

    // See if it's a path within the root package.
    var rootDir = _graph.entrypoint.root.dir;
    var sourcePath = path.fromUri(url);
    if (isBeneath(sourcePath, rootDir)) {
      var relative = path.relative(sourcePath, from: rootDir);
      return new AssetId(_graph.entrypoint.root.name, relative);
    }

    return null;
  }

  // TODO(rnystrom): These are in the public SourceFileProvider interface, but
  // aren't actually used by dart2js. Ideally, these would be taken out of
  // SourceFileProvider (#13671). Until then, just shut up the warnings.
  bool get isWindows => _notSupported();
  set isWindows(value) => _notSupported();
  Uri get cwd => _notSupported();
  set cwd(value) => _notSupported();
  int get dartCharactersRead => _notSupported();
  set dartCharactersRead(value) => _notSupported();
  set sourceFiles(value) => _notSupported();

  _notSupported() => throw new UnsupportedError(
      "This should be private in SourceFileProvider.");
}
