// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.builder_graph;

import 'package:kernel/kernel.dart' show LibraryDependency, LibraryPart;

import 'package:kernel/util/graph.dart' show Graph;

import 'builder/library_builder.dart';

import 'export.dart' show Export;

import 'import.dart' show Import;

import 'dill/dill_library_builder.dart' show DillLibraryBuilder;

import 'source/source_library_builder.dart' show SourceLibraryBuilder;

import 'incremental_compiler.dart' show getPartUri;

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
        // 'imported' can be null for fake imports, such as dart-ext:.
        if (import.imported != null) {
          Uri uri = import.imported.importUri;
          if (builders.containsKey(uri)) {
            yield uri;
          }
        }
      }
      for (Export export in library.exports) {
        Uri uri = export.exported.importUri;
        if (builders.containsKey(uri)) {
          yield uri;
        }
      }
      for (SourceLibraryBuilder part in library.parts) {
        Uri uri = part.importUri;
        if (builders.containsKey(uri)) {
          yield uri;
        }
      }
    } else if (library is DillLibraryBuilder) {
      // Imports and exports
      for (LibraryDependency dependency in library.library.dependencies) {
        Uri uri = dependency.targetLibrary.importUri;
        if (builders.containsKey(uri)) {
          yield uri;
        }
      }

      // Parts
      for (LibraryPart part in library.library.parts) {
        Uri uri = getPartUri(library.importUri, part);
        if (builders.containsKey(uri)) {
          yield uri;
        }
      }
    }
  }
}
