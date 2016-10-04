// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.repository;

import 'dart:io';

import 'package:path/path.dart' as pathlib;

import 'ast.dart';

/// Keeps track of which [Library] objects have been created for a given URI.
///
/// To load different files into the same IR, pass in the same repository
/// object to the loaders.
class Repository {
  final String workingDirectory;
  final Map<Uri, Library> _uriToLibrary = <Uri, Library>{};
  final List<Library> libraries = <Library>[];

  Repository({String workingDirectory})
      : this.workingDirectory = workingDirectory ?? Directory.current.path;

  /// Get the [Library] object for the library addresesd by [path]; possibly
  /// as an external library.
  ///
  /// The [path] may be a relative or absolute file path, or a URI string with a
  /// `dart:`, `package:` or `file:` scheme.
  ///
  /// Note that this method does not check if the library can be loaded at all.
  Library getLibrary(String path) {
    return getLibraryReference(normalizePath(path));
  }

  String normalizeFileExtension(String path) {
    if (path.endsWith('.dill')) {
      return path.substring(0, path.length - '.dill'.length) + '.dart';
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
    var library = new Library(uri, isExternal: true);
    libraries.add(library);
    return library;
  }
}
