// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_graph;

import 'package:kernel/kernel.dart' show Library;

import '../export.dart' show Export;

import '../graph/graph.dart' show Graph;

import '../import.dart' show Import;

import 'source_library_builder.dart' show SourceLibraryBuilder;

import 'source_loader.dart' show SourceLoader;

class SourceGraph implements Graph<Uri> {
  final SourceLoader<Library> loader;

  SourceGraph(this.loader);

  Iterable<Uri> get vertices {
    return loader.builders.keys.where((Uri uri) {
      return loader.builders[uri].loader == loader;
    });
  }

  Iterable<Uri> neighborsOf(Uri vertex) sync* {
    SourceLibraryBuilder library = loader.builders[vertex];
    if (library == null) {
      throw "Library not found: $vertex";
    }
    assert(library.loader == loader);
    for (Import import in library.imports) {
      if (import.imported.loader == loader) {
        yield import.imported.uri;
      }
    }
    for (Export export in library.exports) {
      if (export.exported.loader == loader) {
        yield export.exported.uri;
      }
    }
    for (SourceLibraryBuilder part in library.parts) {
      if (part.loader == loader) {
        if (loader.builders[part.uri] != null) {
          // TODO(ahe): This seems fishy. Are we removing parts from builders?
          yield part.uri;
        }
      }
    }
  }
}
