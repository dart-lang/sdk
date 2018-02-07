// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.builder_graph;

import 'builder/builder.dart' show LibraryBuilder;

import 'export.dart' show Export;

import 'graph/graph.dart' show Graph;

import 'import.dart' show Import;

import 'dill/dill_library_builder.dart' show DillLibraryBuilder;

import 'source/source_library_builder.dart' show SourceLibraryBuilder;

class BuilderGraph implements Graph<Uri> {
  final Map<Uri, LibraryBuilder> builders;

  BuilderGraph(this.builders);

  Iterable<Uri> get vertices => builders.keys;

  Iterable<Uri> neighborsOf(Uri vertex) sync* {
    LibraryBuilder library = builders[vertex];
    if (library == null) {
      throw "Library not found: $vertex";
    }
    if (library is SourceLibraryBuilder) {
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
    } else if (library is DillLibraryBuilder) {
      // Imports and exports
      for (var dependency in library.library.dependencies) {
        var uriString;
        if (dependency.importedLibraryReference.node != null) {
          uriString = '${dependency.targetLibrary.importUri}';
        } else {
          uriString =
              '${dependency.importedLibraryReference.canonicalName.name}';
        }
        Uri uri = Uri.parse(uriString);
        if (builders.containsKey(uri)) {
          yield uri;
        }
      }

      // Parts
      for (var part in library.library.parts) {
        Uri uri = part.fileUri;
        if (builders.containsKey(uri)) {
          yield uri;
        }
      }
    }
  }
}
