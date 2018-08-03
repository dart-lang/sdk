// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.library_graph;

import 'package:kernel/kernel.dart' show Library, LibraryDependency;

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
      Uri uri1 = dependency.targetLibrary.importUri;
      Uri uri2 = dependency.targetLibrary.fileUri;
      if (libraries.containsKey(uri1)) {
        yield uri1;
      } else if (uri2 != null) {
        if (libraries.containsKey(uri2)) {
          yield uri2;
        }
      }
    }
  }
}
