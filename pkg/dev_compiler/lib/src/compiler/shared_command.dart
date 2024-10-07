// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_prototype/macros.dart' as macros
    show isMacroLibraryUri;
import 'package:front_end/src/api_unstable/ddc.dart'
    show InitializedCompilerState;
import 'package:path/path.dart' as p;

// TODO(nshahan) Merge all of this file the locations where they are used in
// the kernel (only) version of DDC.

/// Convert a [source] string to a Uri, where the source may be a
/// dart/file/package URI or a local win/mac/linux path.
Uri sourcePathToUri(String source, {bool? windows}) {
  if (windows == null) {
    // Running on the web the Platform check will fail, and we can't use
    // fromEnvironment because internally it's set to true for dart.library.io.
    // So just catch the exception and if it fails then we're definitely not on
    // Windows.
    try {
      windows = Platform.isWindows;
    } catch (e) {
      windows = false;
    }
  }
  if (windows) {
    source = source.replaceAll('\\', '/');
  }

  var result = Uri.base.resolve(source);
  if (windows && result.scheme.length == 1) {
    // Assume c: or similar --- interpret as file path.
    return Uri.file(source, windows: true);
  }
  return result;
}

Uri sourcePathToRelativeUri(String source, {bool? windows}) {
  var uri = sourcePathToUri(source, windows: windows);
  if (uri.isScheme('file')) {
    var uriPath = uri.path;
    var root = Uri.base.path;
    if (uriPath.startsWith(root)) {
      return p.toUri(uriPath.substring(root.length));
    }
  }
  return uri;
}

/// Adjusts the source uris in [sourceMap] to be relative uris, and returns
/// the new map.
///
/// Source uris show up in two forms, absolute `file:` uris and custom
/// [multiRootScheme] uris (also "absolute" uris, but always relative to some
/// multi-root).
///
/// - `file:` uris are converted to be relative to [sourceMapBase], which
///   defaults to the dirname of [sourceMapPath] if not provided.
///
/// - [multiRootScheme] uris are prefixed by [multiRootOutputPath]. If the
///   path starts with `/lib`, then we strip that before making it relative
///   to the [multiRootOutputPath], and assert that [multiRootOutputPath]
///   starts with `/packages` (more explanation inline).
///
// TODO(#40251): Remove this logic from dev_compiler itself, push it to the
// invokers of dev_compiler which have more knowledge about how they want
// source paths to look.
Map<String, Object?> placeSourceMap(Map<String, Object?> sourceMap,
    String sourceMapPath, String? multiRootScheme,
    {String? multiRootOutputPath, String? sourceMapBase}) {
  var map = Map.of(sourceMap);
  // Convert to a local file path if it's not.
  sourceMapPath = sourcePathToUri(p.absolute(p.fromUri(sourceMapPath))).path;
  var sourceMapDir = p.url.dirname(sourceMapPath);
  sourceMapBase ??= sourceMapDir;
  var list = (map['sources'] as List).toList();

  String makeRelative(String sourcePath) {
    var uri = sourcePathToUri(sourcePath);
    var scheme = uri.scheme;
    if (scheme == 'dart' || scheme == 'package' || scheme == multiRootScheme) {
      if (scheme == multiRootScheme) {
        // TODO(sigmund): extract all source-map normalization outside ddc. This
        // custom logic is BUILD specific and could be shared with other tools
        // like dart2js.
        var shortPath = uri.path.replaceAll('/sdk/', '/dart-sdk/');
        var multiRootPath = "${multiRootOutputPath ?? ''}$shortPath";
        multiRootPath = p.url
            .joinAll(p.split(p.relative(multiRootPath, from: sourceMapDir)));
        return multiRootPath;
      }
      return sourcePath;
    }

    if (macros.isMacroLibraryUri(uri)) {
      // TODO: https://github.com/dart-lang/sdk/issues/53913
      return sourcePath;
    }

    if (uri.isScheme('http')) return sourcePath;

    // Convert to a local file path if it's not.
    sourcePath = sourcePathToUri(p.absolute(p.fromUri(uri))).path;

    // Fall back to a relative path against the source map itself.
    sourcePath = p.url.relative(sourcePath, from: sourceMapBase);

    // Convert from relative local path to relative URI.
    return p.toUri(sourcePath).path;
  }

  for (var i = 0; i < list.length; i++) {
    list[i] = makeRelative(list[i] as String);
  }
  map['sources'] = list;
  map['file'] =
      map['file'] != null ? makeRelative(map['file'] as String) : null;
  return map;
}

/// The result of a single `dartdevc` compilation.
///
/// Typically used for exiting the process with [exitCode] or checking the
/// [success] of the compilation.
///
/// For batch/worker compilations, the [compilerState] provides an opportunity
/// to reuse state from the previous run, if the options/input summaries are
/// equivalent. Otherwise it will be discarded.
class CompilerResult {
  /// Optionally provides the front_end state from the previous compilation,
  /// which can be passed to [compile] to potentially speed up the next
  /// compilation.
  final InitializedCompilerState? kernelState;

  /// The process exit code of the compiler.
  final int exitCode;

  CompilerResult(this.exitCode, {this.kernelState});

  /// Gets the kernel compiler state, if any.
  Object? get compilerState => kernelState;

  /// Whether the program compiled without any fatal errors (equivalent to
  /// [exitCode] == 0).
  bool get success => exitCode == 0;

  /// Whether the compiler crashed (i.e. threw an unhandled exception,
  /// typically indicating an internal error in DDC itself or its front end).
  bool get crashed => exitCode == 70;
}
