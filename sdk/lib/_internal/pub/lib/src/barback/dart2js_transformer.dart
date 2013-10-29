// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.dart2js_transformer;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import '../../../../compiler/compiler.dart' as compiler;
import '../../../../compiler/implementation/dart2js.dart'
    show AbortLeg;
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

  /// The [AssetId]s the transformer has discovered so far. Used by pub build
  /// to determine where to copy the JS bootstrap files.
  // TODO(rnystrom): Do something cleaner for this, or eliminate those files.
  final entrypoints = new Set<AssetId>();

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
        var id = transform.primaryInput.id;
        var name = id.path;
        if (id.package != _graph.entrypoint.root.name) {
          name += " in ${id.package}";
        }

        var parsed = parseCompilationUnit(code, name: name);
        if (!dart.isEntrypoint(parsed)) return;
      } on AnalyzerErrorGroup catch (e) {
        transform.logger.error(e.message);
        return;
      }

      var provider = new _BarbackInputProvider(_graph, transform);

      // Create a "path" to the entrypoint script. The entrypoint may not
      // actually be on disk, but this gives dart2js a root to resolve
      // relative paths against.
      var id = transform.primaryInput.id;

      entrypoints.add(id);

      var entrypoint = path.join(_graph.packages[id.package].dir, id.path);
      var packageRoot = path.join(_graph.entrypoint.root.dir, "packages");

      // TODO(rnystrom): Should have more sophisticated error-handling here.
      // Need to report compile errors to the user in an easily visible way.
      // Need to make sure paths in errors are mapped to the original source
      // path so they can understand them.
      return dart.compile(entrypoint,
          packageRoot: packageRoot,
          inputProvider: provider.readStringFromUri,
          diagnosticHandler: provider.handleDiagnostic).then((js) {
        var id = transform.primaryInput.id.changeExtension(".dart.js");
        transform.addOutput(new Asset.fromString(id, js));

        stopwatch.stop();
        transform.logger.info("Generated $id (${js.length} characters) in "
            "${stopwatch.elapsed}");
      }).catchError((error) {
        // The compile failed and errors have been reported through the
        // diagnostic handler, so just do nothing here.
        if (error is CompilerException) return;
        throw error;
      });
    });
  }
}

/// Defines methods implementig [CompilerInputProvider] and [DiagnosticHandler]
/// for dart2js to use to load files from Barback and report errors.
///
/// Note that most of the implementation of diagnostic handling here was
/// copied from [FormattingDiagnosticHandler] in dart2js. The primary
/// difference is that it uses barback's logging code and, more importantly, it
/// handles missing source files more gracefully.
class _BarbackInputProvider {
  final PackageGraph _graph;
  final Transform _transform;

  /// The map of previously loaded files.
  ///
  /// Used to show where an error occurred in a source file.
  final _sourceFiles = new Map<String, SourceFile>();

  // TODO(rnystrom): Make these configurable.
  /// Whether or not warnings should be logged.
  var _showWarnings = true;

  /// Whether or not hints should be logged.
  var _showHints = true;

  /// Whether or not verbose info messages should be logged.
  var _verbose = false;

  /// Whether an exception should be thrown on an error to stop compilation.
  var _throwOnError = false;

  /// This gets set after a fatal error is reported to quash any subsequent
  /// errors.
  var _isAborting = false;

  compiler.Diagnostic _lastKind = null;

  static final int _FATAL =
      compiler.Diagnostic.CRASH.ordinal |
      compiler.Diagnostic.ERROR.ordinal;
  static final int _INFO =
      compiler.Diagnostic.INFO.ordinal |
      compiler.Diagnostic.VERBOSE_INFO.ordinal;

  _BarbackInputProvider(this._graph, this._transform);

  /// A [CompilerInputProvider] for dart2js.
  Future<String> readStringFromUri(Uri resourceUri) {
    // We only expect to get absolute "file:" URLs from dart2js.
    assert(resourceUri.isAbsolute);
    assert(resourceUri.scheme == "file");

    var sourcePath = path.fromUri(resourceUri);
    return _readResource(resourceUri).then((source) {
      _sourceFiles[resourceUri.toString()] =
          new StringSourceFile(path.relative(sourcePath), source);
      return source;
    });
  }

  /// A [DiagnosticHandler] for dart2js, loosely based on
  /// [FormattingDiagnosticHandler].
  void handleDiagnostic(Uri uri, int begin, int end,
                        String message, compiler.Diagnostic kind) {
    // TODO(ahe): Remove this when source map is handled differently.
    if (kind.name == "source map") return;

    if (_isAborting) return;
    _isAborting = (kind == compiler.Diagnostic.CRASH);

    var isInfo = (kind.ordinal & _INFO) != 0;
    if (isInfo && uri == null && kind != compiler.Diagnostic.INFO) {
      if (!_verbose && kind == compiler.Diagnostic.VERBOSE_INFO) return;
      _transform.logger.info(message);
      return;
    }

    // [_lastKind] records the previous non-INFO kind we saw.
    // This is used to suppress info about a warning when warnings are
    // suppressed, and similar for hints.
    if (kind != compiler.Diagnostic.INFO) _lastKind = kind;

    var logFn;
    if (kind == compiler.Diagnostic.ERROR) {
      logFn = _transform.logger.error;
    } else if (kind == compiler.Diagnostic.WARNING) {
      if (!_showWarnings) return;
      logFn = _transform.logger.warning;
    } else if (kind == compiler.Diagnostic.HINT) {
      if (!_showHints) return;
      logFn = _transform.logger.warning;
    } else if (kind == compiler.Diagnostic.CRASH) {
      logFn = _transform.logger.error;
    } else if (kind == compiler.Diagnostic.INFO) {
      if (_lastKind == compiler.Diagnostic.WARNING && !_showWarnings) return;
      if (_lastKind == compiler.Diagnostic.HINT && !_showHints) return;
      logFn = _transform.logger.info;
    } else {
      throw new Exception('Unknown kind: $kind (${kind.ordinal})');
    }

    var fatal = (kind.ordinal & _FATAL) != 0;
    if (uri == null) {
      assert(fatal);
      logFn(message);
    } else {
      SourceFile file = _sourceFiles[uri.toString()];
      if (file == null) {
        // We got a message before loading the file, so just report the message
        // itself.
        logFn('$uri: $message');
      } else {
        logFn(file.getLocationMessage(message, begin, end, true, (i) => i));
      }
    }

    if (fatal && _throwOnError) {
      _isAborting = true;
      throw new AbortLeg(message);
    }
  }

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
}
