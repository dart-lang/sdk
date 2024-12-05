// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(bkonyi): consider moving to lib/ once this package is no longer shipped
// via pub.

import 'dart:async';
import 'dart:collection';
import 'dart:io' as io;

import 'package:path/path.dart';

/// A URI converter able to handle google3 URIs.
class BazelUriConverter {
  final _absoluteUriToFileCache = HashMap<Uri, String>();
  final Context _context = context;
  final _binPaths = <String>[];
  final String _root;
  String? _genfiles;
  final _bazelCandidateFiles = StreamController<BazelSearchInfo>.broadcast();

  BazelUriConverter(String originalPath) : _root = originalPath {
    _ensureAbsoluteAndNormalized(originalPath);
    // Note: The analyzer code this code is based on checked multiple things
    // while trying to find a google3 workspace - the presence of a blaze-out
    // directory, a READONLY file or a WORKSPACE file. If the blaze-out
    // structure changes, then potentially check for one of the others.
    final blazeOutDir =
        io.Directory(normalize(join(originalPath, 'blaze-out')));
    if (blazeOutDir.existsSync()) {
      _binPaths.addAll(_findBinFolderPaths(blazeOutDir));
      _binPaths.add(normalize(join(originalPath, 'blaze-bin')));
      _genfiles = normalize(join(originalPath, 'blaze-genfiles'));
    }
  }

  String? uriToPath(String uriStr) {
    final uri = Uri.parse(uriStr);
    final cached = _absoluteUriToFileCache[uri];
    if (cached != null) {
      return cached;
    }

    if (uri.isScheme('file')) {
      final path = fileUriToNormalizedPath(_context, uri);
      final pathRelativeToRoot = _relativeToRoot(path);
      if (pathRelativeToRoot == null) return null;
      final fullFilePath = _context.join(_root, pathRelativeToRoot);
      final file = _findFile(fullFilePath);
      if (file != null) {
        _absoluteUriToFileCache[uri] = file.path;
        return file.path;
      }
    }
    // If the URI passed has a google3 scheme, this means we don't need to
    // convert from a package URI and we only need to prepend the root path
    // (i.e. the path that contains the user's workspace name).
    if (uri.isScheme('google3')) {
      // Remove the first character since uri.path starts with '/', though we
      // know this is not an absolute path.
      return _context.join(_root, uri.path.substring(1));
    }
    if (!uri.isScheme('package')) {
      // TODO(b/261234406): Handle `dart:` URIs.
      if (uri.isScheme('dart')) {
        // This doesn't return the actual location of the Dart SDK, which is
        // more complicated. The purpose of returning something here is to
        // avoid having the external version of URI converter resolving a path
        // that is incorrect in a way that confuse VS Code's stack trace.
        return _context.join(_root, uri.path);
      }
      return null;
    }
    final uriPath = Uri.decodeComponent(uri.path);
    final slash = uriPath.indexOf('/');

    // If the path either starts with a slash or has no slash, it is invalid.
    if (slash < 1) {
      return null;
    }

    if (uriPath.contains('//') || uriPath.contains('..')) {
      return null;
    }

    final packageName = uriPath.substring(0, slash);

    final fileUriPart = uriPath.substring(slash + 1);
    if (fileUriPart.isEmpty) {
      return null;
    }

    final filePath = fileUriPart.replaceAll('/', _context.separator);

    if (!packageName.contains('.')) {
      final fullFilePath = _context.join(
          _root, 'third_party', 'dart', packageName, 'lib', filePath);
      final file = _findFile(fullFilePath);
      if (file != null) {
        _absoluteUriToFileCache[uri] = file.path;
        return file.path;
      }
    } else {
      final packagePath = packageName.replaceAll('.', _context.separator);
      final fullFilePath = _context.join(_root, packagePath, 'lib', filePath);
      final file = _findFile(fullFilePath);
      if (file != null) {
        _absoluteUriToFileCache[uri] = file.path;
        return file.path;
      }
    }
    return null;
  }

  String fileUriToNormalizedPath(Context context, Uri fileUri) {
    assert(fileUri.isScheme('file'));
    var contextPath = context.fromUri(fileUri);
    contextPath = context.normalize(contextPath);
    return contextPath;
  }

  /// The file system abstraction supports only absolute and normalized paths.
  /// This method is used to validate any input paths to prevent errors later.
  void _ensureAbsoluteAndNormalized(String path) {
    assert(() {
      if (!_context.isAbsolute(path)) {
        throw ArgumentError('Path must be absolute : $path');
      }
      if (_context.normalize(path) != path) {
        throw ArgumentError('Path must be normalized : $path');
      }
      return true;
    }());
  }

  List<String> _findBinFolderPaths(io.Directory blazeOutDir) {
    final binPaths = <String>[];
    for (final child
        in blazeOutDir.listSync(recursive: false).whereType<io.Directory>()) {
      // Children are folders denoting architectures and build flags, like
      // 'k8-opt', 'k8-fastbuild', perhaps 'host'.

      final possibleBin = io.Directory(normalize(join(child.path, 'bin')));
      if (possibleBin.existsSync()) {
        binPaths.add(possibleBin.path);
      }
    }
    return binPaths;
  }

  String? _relativeToRoot(String p) {
    // genfiles
    if (_genfiles != null && _context.isWithin(_genfiles!, p)) {
      return context.relative(p, from: _genfiles!);
    }
    // bin
    for (final bin in _binPaths) {
      if (context.isWithin(bin, p)) {
        return context.relative(p, from: bin);
      }
    }

    // We are no longer checking for READONLY? Or should I add back?
    // READONLY
    // final readonly = this.readonly;
    // if (readonly != null) {
    //   if (context.isWithin(readonly, p)) {
    //     return context.relative(p, from: readonly);
    //   }
    // }
    // Not generated
    if (context.isWithin(_root, p)) {
      return context.relative(p, from: _root);
    }
    // Failed reverse lookup
    return null;
  }

  /// Return the file with the given [absolutePath], looking first into
  /// directories for generated files: `bazel-bin` and `bazel-genfiles`, and
  /// then into the workspace originalPath. The file in the workspace originalPath is returned
  /// even if it does not exist. Return `null` if the given [absolutePath] is
  /// not in the workspace [originalPath].
  io.File? _findFile(String absolutePath) {
    try {
      final relative = _context.relative(absolutePath, from: _root);
      if (relative == '.') {
        return null;
      }
      // First check genfiles and bin directories. Note that we always use the
      // symlinks and not the [binPaths] or [genfiles] to make sure we use the
      // files corresponding to the most recent build configuration and get
      // consistent view of all the generated files.
      final generatedCandidates = ['blaze-genfiles', 'blaze-bin']
          .map((prefix) => context.join(_root, context.join(prefix, relative)));
      for (final path in generatedCandidates) {
        _ensureAbsoluteAndNormalized(path);
        final file = io.File(path);
        if (file.existsSync()) {
          _bazelCandidateFiles
              .add(BazelSearchInfo(relative, generatedCandidates.toList()));
          return file;
        }
      }
      // Writable
      _ensureAbsoluteAndNormalized(absolutePath);
      final writableFile = io.File(absolutePath);
      if (writableFile.existsSync()) {
        return writableFile;
      }

      // If we couldn't find the file, assume that it has not yet been
      // generated, so send an event with all the paths that we tried.
      _bazelCandidateFiles
          .add(BazelSearchInfo(relative, generatedCandidates.toList()));
      // Not generated, return the default one.
      return writableFile;
    } catch (_) {
      return null;
    }
  }
}

/// Notification that we issue when searching for generated files in a Bazel
/// workspace.
///
/// This allows clients to watch for changes to the generated files.
class BazelSearchInfo {
  /// Candidate paths that we searched.
  final List<String> candidatePaths;

  /// Absolute path that we tried searching for.
  ///
  /// This is not necessarily the path of the actual file that will be used. See
  /// `BazelWorkspace.findFile` for details.
  final String requestedPath;

  BazelSearchInfo(this.requestedPath, this.candidatePaths);
}
