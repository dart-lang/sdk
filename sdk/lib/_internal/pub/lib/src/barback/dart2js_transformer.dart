// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.dart2js_transformer;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';

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

  /// The mode that the transformer is running in.
  final BarbackMode _mode;

  /// The [AssetId]s the transformer has discovered so far. Used by pub build
  /// to determine where to copy the JS bootstrap files.
  // TODO(rnystrom): Do something cleaner for this, or eliminate those files.
  final entrypoints = new Set<AssetId>();

  /// If this is non-null, then the transformer is currently being applied, so
  /// subsequent calls to [apply] will wait for this to finish before
  /// proceeding.
  ///
  /// Dart2js uses lots of memory, so if we try to actually run compiles in
  /// parallel, it takes down the VM. Instead, the transformer will force
  /// all applies to be sequential. The tracking bug to do something better
  /// is here: https://code.google.com/p/dart/issues/detail?id=14730.
  Future _running;

  Dart2JSTransformer(this._graph, this._mode);

  /// Only ".dart" files within "web/" are processed.
  Future<bool> isPrimary(Asset asset) {
    return new Future.value(
        asset.id.extension == ".dart" &&
        asset.id.path.startsWith("web/"));
  }

  Future apply(Transform transform) {
    // Wait for any ongoing apply to finish first.
    // TODO(rnystrom): If there are multiple simultaneous compiles, this will
    // resume and pause them repeatedly. It still serializes them correctly,
    // but it might be cleaner to use a real queue.
    // TODO(rnystrom): Add a test that this is functionality is helpful.
    if (_running != null) {
      return _running.then((_) => apply(transform));
    }

    var completer = new Completer();
    _running = completer.future;

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
        if (!dart.isEntrypoint(parsed)) return null;
      } on AnalyzerErrorGroup catch (e) {
        transform.logger.error(e.message);
        return null;
      }

      var provider = new _BarbackCompilerProvider(_graph, transform);

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
      return Chain.track(dart.compile(
          entrypoint, provider,
          packageRoot: packageRoot,
          minify: _mode == BarbackMode.RELEASE)).then((_) {
        stopwatch.stop();
        transform.logger.info("Took ${stopwatch.elapsed} to compile $id.");
      });
    }).whenComplete(() {
      completer.complete();
      _running = null;
    });
  }
}

/// Defines an interface for dart2js to communicate with barback and pub.
///
/// Note that most of the implementation of diagnostic handling here was
/// copied from [FormattingDiagnosticHandler] in dart2js. The primary
/// difference is that it uses barback's logging code and, more importantly, it
/// handles missing source files more gracefully.
class _BarbackCompilerProvider implements dart.CompilerProvider {
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

  _BarbackCompilerProvider(this._graph, this._transform);

  /// A [CompilerInputProvider] for dart2js.
  Future<String> provideInput(Uri resourceUri) {
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

  /// A [CompilerOutputProvider] for dart2js.
  EventSink<String> provideOutput(String name, String extension) {
    // Dart2js uses an empty string for the name of the entrypoint library.
    // We only expect to get output files associated with that right now. For
    // other files, we'd need some logic to determine the right relative path
    // for it.
    assert(name == "");

    var primaryId = _transform.primaryInput.id;
    var id = new AssetId(primaryId.package, "${primaryId.path}.$extension");

    // Make a sink that dart2js can write to.
    var sink = new StreamController<String>();

    // dart2js gives us strings, but stream assets expect byte lists.
    var stream = UTF8.encoder.bind(sink.stream);

    // And give it to barback as a stream it can read from.
    _transform.addOutput(new Asset.fromStream(id, stream));

    return sink;
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
    return Chain.track(new File(sourcePath).readAsString());
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
