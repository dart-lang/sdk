// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:io' as io;

import 'package:path/path.dart' as path;

const _kBinDir = 'bin';
const _kBlazeBinDir = 'blaze-bin';
const _kBlazeGenfilesDir = 'blaze-genfiles';
const _kBlazeOutDir = 'blaze-out';
const _kDartDir = 'dart';
const _kGeneratedPrefixes = <String>[_kBlazeGenfilesDir, _kBlazeBinDir];
const _kLibDir = 'lib';
const _kThirdPartyDir = 'third_party';

/// A URI converter able to handle google3 URIs.
class BazelUriConverter {
  /// Creates a [BazelUriConverter] rooted at [originalPath], which must be an
  /// absolute and normalized workspace directory path.
  BazelUriConverter(String originalPath) : _root = originalPath {
    _ensureAbsoluteAndNormalized(originalPath);
    // Note: The analyzer code this code is based on checked multiple things
    // while trying to find a google3 workspace - the presence of a blaze-out
    // directory, a READONLY file or a WORKSPACE file. If the blaze-out
    // structure changes, then potentially check for one of the others.
    final blazeOutDir = io.Directory(
      path.normalize(path.join(originalPath, _kBlazeOutDir)),
    );
    if (blazeOutDir.existsSync()) {
      _binPaths
        ..addAll(_findBinFolderPaths(blazeOutDir))
        ..add(path.normalize(path.join(originalPath, _kBlazeBinDir)));
      _genfiles = path.normalize(path.join(originalPath, _kBlazeGenfilesDir));
    }
  }

  final _absoluteUriToFileCache = HashMap<Uri, String>();
  final path.Context _context = path.context;
  final _binPaths = <String>[];
  final String _root;
  String? _genfiles;

  /// Converts [uriStr] to an absolute local file path within the Google3
  /// workspace, or returns `null` if the URI cannot be resolved.
  String? uriToPath(String uriStr) {
    final uri = Uri.parse(uriStr);
    final cached = _absoluteUriToFileCache[uri];
    if (cached != null) {
      return cached;
    }

    if (uri.isScheme('file')) {
      final filePath = _fileUriToNormalizedPath(uri);
      final pathRelativeToRoot = _relativeToRoot(filePath);
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
      return _context.joinAll([_root, ...uri.pathSegments]);
    }
    if (!uri.isScheme('package')) {
      // TODO(b/261234406): Handle `dart:` URIs.
      if (uri.isScheme('dart')) {
        // This doesn't return the actual location of the Dart SDK, which is
        // more complicated. The purpose of returning something here is to
        // avoid having the external version of URI converter resolving a path
        // that is incorrect in a way that confuse VS Code's stack trace.
        return _context.joinAll([_root, ...uri.pathSegments]);
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
        _root,
        _kThirdPartyDir,
        _kDartDir,
        packageName,
        _kLibDir,
        filePath,
      );
      final file = _findFile(fullFilePath);
      if (file != null) {
        _absoluteUriToFileCache[uri] = file.path;
        return file.path;
      }
    } else {
      final packagePath = packageName.replaceAll('.', _context.separator);
      final fullFilePath = _context.join(
        _root,
        packagePath,
        _kLibDir,
        filePath,
      );
      final file = _findFile(fullFilePath);
      if (file != null) {
        _absoluteUriToFileCache[uri] = file.path;
        return file.path;
      }
    }
    return null;
  }

  String _fileUriToNormalizedPath(Uri fileUri) {
    assert(fileUri.isScheme('file'));
    final contextPath = _context.fromUri(fileUri);
    return _context.normalize(contextPath);
  }

  /// The file system abstraction supports only absolute and normalized paths.
  /// This method is used to validate any input paths to prevent errors later.
  void _ensureAbsoluteAndNormalized(String filePath) {
    assert(() {
      if (!_context.isAbsolute(filePath)) {
        throw ArgumentError('Path must be absolute : $filePath');
      }
      if (_context.normalize(filePath) != filePath) {
        throw ArgumentError('Path must be normalized : $filePath');
      }
      return true;
    }());
  }

  List<String> _findBinFolderPaths(io.Directory blazeOutDir) {
    final binPaths = <String>[];
    for (final child in blazeOutDir.listSync().whereType<io.Directory>()) {
      // Children are folders denoting architectures and build flags, like
      // 'k8-opt', 'k8-fastbuild', perhaps 'host'.
      final possibleBin = io.Directory(
        path.normalize(path.join(child.path, _kBinDir)),
      );
      if (possibleBin.existsSync()) {
        binPaths.add(possibleBin.path);
      }
    }
    return binPaths;
  }

  String? _relativeToRoot(String p) {
    final genfiles = _genfiles;
    // genfiles
    if (genfiles != null && _context.isWithin(genfiles, p)) {
      return _context.relative(p, from: genfiles);
    }
    // bin
    for (final bin in _binPaths) {
      if (_context.isWithin(bin, p)) {
        return _context.relative(p, from: bin);
      }
    }

    // Not generated
    if (_context.isWithin(_root, p)) {
      return _context.relative(p, from: _root);
    }
    // Failed reverse lookup
    return null;
  }

  /// Return the file with the given [absolutePath], looking first into
  /// directories for generated files: `bazel-bin` and `bazel-genfiles`, and
  /// then into the workspace originalPath. The file in the workspace
  /// originalPath is returned even if it does not exist. Return `null` if the
  /// given [absolutePath] is not in the workspace `originalPath`.
  io.File? _findFile(String absolutePath) {
    try {
      final relative = _context.relative(absolutePath, from: _root);
      if (relative == '.') {
        return null;
      }
      // First check genfiles and bin directories. Note that we always use the
      // symlinks and not the [_binPaths] or [_genfiles] to make sure we use the
      // files corresponding to the most recent build configuration and get
      // consistent view of all the generated files.
      final generatedCandidates = _kGeneratedPrefixes.map(
        (prefix) => _context.join(_root, _context.join(prefix, relative)),
      );
      for (final candidatePath in generatedCandidates) {
        _ensureAbsoluteAndNormalized(candidatePath);
        final file = io.File(candidatePath);
        if (file.existsSync()) {
          return file;
        }
      }
      // Writable (returned even if it has not yet been generated on disk).
      _ensureAbsoluteAndNormalized(absolutePath);
      return io.File(absolutePath);
    } on Object {
      return null;
    }
  }
}
