// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.library_graph;

import 'package:kernel/kernel.dart'
    show Library, LibraryDependency, LibraryPart;

import 'package:kernel/util/graph.dart' show Graph;

class LibraryGraph implements Graph<Uri> {
  final Map<Uri, Library> libraries;

  LibraryGraph(this.libraries);

  Iterable<Uri> get vertices => libraries.keys;

  Iterable<Uri> neighborsOf(Uri vertex) sync* {
    Library library = libraries[vertex];
    if (library == null) {
      throw "Library not found: $vertex";
    }
    // Imports and exports
    for (LibraryDependency dependency in library.dependencies) {
      String uriString;
      if (dependency.importedLibraryReference.node != null) {
        uriString = '${dependency.targetLibrary.importUri}';
      } else {
        uriString = '${dependency.importedLibraryReference.canonicalName.name}';
      }
      Uri uri = Uri.parse(uriString);
      if (libraries.containsKey(uri)) {
        yield uri;
      }
    }

    // Parts
    for (LibraryPart part in library.parts) {
      Uri uri = part.fileUri;
      if (libraries.containsKey(uri)) {
        yield uri;
      }
    }
  }
}
