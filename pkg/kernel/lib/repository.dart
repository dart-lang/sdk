// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.repository;

import 'ast.dart';
import 'package:path/path.dart' as pathlib;
import 'dart:io';
import 'analyzer/loader.dart';

/// Resolves import paths and keeps track of which [Library] objects have been
/// created for a given URI.
///
/// To load different files into the same IR, pass in the same repository
/// object to the loaders.
class Repository {
  final String sdk;
  final String packageRoot;
  final String workingDirectory;
  final Map<Uri, Library> _uriToLibrary = <Uri, Library>{};
  final List<Library> libraries = <Library>[];
  AnalyzerLoader _analyzerLoader;

  /// Whether strong mode should be enabled for this repository.
  ///
  /// This is a flag on the repository itself because strong mode and non-strong
  /// mode code should not be mixed.
  final bool strongMode;

  Repository(
      {this.sdk,
      this.packageRoot,
      String workingDirectory,
      AnalyzerLoader analyzerLoader,
      this.strongMode})
      : this.workingDirectory = workingDirectory ?? Directory.current.path,
        _analyzerLoader = analyzerLoader;

  /// Get the [Library] object for the library addresesd by [path]; possibly
  /// unloaded.
  ///
  /// The [path] may be a relative or absolute file path, or a URI string with a
  /// `dart:`, `package:` or `file:` scheme.
  ///
  /// Note that this method does not check if the library can be loaded at all.
  Library getLibrary(String path) {
    return getLibraryReference(normalizePath(path));
  }

  /// Get the system file path to read the given URI.
  String resolveUri(Uri uri) {
    switch (uri.scheme) {
      case 'dart':
        if (sdk == null) {
          throw 'Cannot resolve $uri because no sdk path is set';
        }
        if (uri.pathSegments.length == 1) {
          var name = uri.pathSegments.single;
          return pathlib.join(sdk, 'lib', name, '$name.dart');
        }
        return pathlib.join(sdk, 'lib', uri.path);

      case 'package':
        if (packageRoot == null) {
          throw 'Cannot resolve $uri because no package root is set';
        }
        return pathlib.join(packageRoot, uri.path);

      case 'file':
        return uri.toFilePath();
    }
    throw 'Unrecognized URI scheme: $uri';
  }

  String normalizeFileExtension(String path) {
    if (path.endsWith('.bart')) {
      return path.substring(0, path.length - '.bart'.length) + '.dart';
    } else {
      return path;
    }
  }

  /// Get the canonical URI for the library addressed by the given [path].
  ///
  /// The [path] may be a relative or absolute file path, or a URI string with a
  /// `dart:`, `package:` or `file:` scheme.
  Uri normalizePath(String path) {
    var uri = Uri.parse(path);
    if (!uri.hasScheme) {
      if (!pathlib.isAbsolute(path)) {
        path = pathlib.join(workingDirectory, path);
      }
      uri = new Uri(scheme: 'file', path: normalizeFileExtension(path));
    } else if (uri.scheme == 'file') {
      var path = normalizeFileExtension(uri.path);
      if (!uri.hasAbsolutePath) {
        uri = uri.replace(path: pathlib.join(workingDirectory, path));
      } else {
        uri = uri.replace(path: path);
      }
    }
    return uri;
  }

  Library getLibraryReference(Uri uri) {
    assert(uri.hasScheme);
    assert(uri.scheme != 'file' || uri.hasAbsolutePath);
    return _uriToLibrary.putIfAbsent(uri, () => _buildLibraryReference(uri));
  }

  Library _buildLibraryReference(Uri uri) {
    var library = new Library(uri)..isLoaded = false;
    libraries.add(library);
    return library;
  }

  /// Gets the repository state that keeps track of how the analyzer's element
  /// model relates to the kernel IR.
  AnalyzerLoader getAnalyzerLoader() {
    return _analyzerLoader ??= new AnalyzerLoader(this, strongMode: strongMode);
  }
}
