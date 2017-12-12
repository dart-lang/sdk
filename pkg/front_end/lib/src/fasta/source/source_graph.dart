// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_graph;

import '../builder/builder.dart' show LibraryBuilder;

import '../export.dart' show Export;

import '../graph/graph.dart' show Graph;

import '../import.dart' show Import;

import 'source_library_builder.dart' show SourceLibraryBuilder;

class SourceGraph implements Graph<Uri> {
  final Map<Uri, LibraryBuilder> builders;

  SourceGraph(this.builders);

  Iterable<Uri> get vertices => builders.keys;

  Iterable<Uri> neighborsOf(Uri vertex) sync* {
    SourceLibraryBuilder library = builders[vertex];
    if (library == null) {
      throw "Library not found: $vertex";
    }
    for (Import import in library.imports) {
      Uri uri = import.imported.uri;
      if (builders.containsKey(uri)) {
        yield uri;
      }
    }
    for (Export export in library.exports) {
      Uri uri = export.exported.uri;
      if (builders.containsKey(uri)) {
        yield uri;
      }
    }
    for (SourceLibraryBuilder part in library.parts) {
      Uri uri = part.uri;
      if (builders.containsKey(uri)) {
        yield uri;
      }
    }
  }
}
