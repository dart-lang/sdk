// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.repository;

import 'ast.dart';

/// Keeps track of which [Library] objects have been created for a given URI.
///
/// To load different files into the same IR, pass in the same repository
/// object to the loaders.
class Repository {
  final Map<Uri, Library> _uriToLibrary = <Uri, Library>{};
  final List<Library> libraries = <Library>[];

  Library getLibraryReference(Uri uri) {
    assert(uri.hasScheme);
    return _uriToLibrary.putIfAbsent(uri, () => _buildLibraryReference(uri));
  }

  Library _buildLibraryReference(Uri uri) {
    assert(uri.hasScheme);
    var library = new Library(uri, isExternal: true);
    libraries.add(library);
    return library;
  }
}
