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

import 'source/source_library_builder.dart' show Part, SourceLibraryBuilder;

import 'incremental_compiler.dart' show getPartUri;

class BuilderGraph implements Graph<Uri> {
  final Map<Uri, LibraryBuilder> libraryBuilders;

  final Map<Uri, List<Uri>> _neighborsCache = {};

  BuilderGraph(this.libraryBuilders);

  @override
  Iterable<Uri> get vertices => libraryBuilders.keys;

  List<Uri> _computeNeighborsOf(Uri vertex) {
    List<Uri> neighbors = [];
    LibraryBuilder? libraryBuilder = libraryBuilders[vertex];
    if (libraryBuilder == null) {
      throw "Library not found: $vertex";
    }
    if (libraryBuilder is SourceLibraryBuilder) {
      for (Import import in libraryBuilder.imports) {
        // 'imported' can be null for fake imports, such as dart-ext:.
        if (import.importedCompilationUnit != null) {
          Uri uri = import.importedLibraryBuilder!.importUri;
          if (libraryBuilders.containsKey(uri)) {
            neighbors.add(uri);
          }
        }
      }
      for (Export export in libraryBuilder.exports) {
        Uri uri = export.exportedLibraryBuilder.importUri;
        if (libraryBuilders.containsKey(uri)) {
          neighbors.add(uri);
        }
      }
      for (Part part in libraryBuilder.parts) {
        Uri uri = part.compilationUnit.importUri;
        if (libraryBuilders.containsKey(uri)) {
          neighbors.add(uri);
        }
      }
    } else if (libraryBuilder is DillLibraryBuilder) {
      // Imports and exports
      for (LibraryDependency dependency
          in libraryBuilder.library.dependencies) {
        Uri uri = dependency.targetLibrary.importUri;
        if (libraryBuilders.containsKey(uri)) {
          neighbors.add(uri);
        }
      }

      // Parts
      for (LibraryPart part in libraryBuilder.library.parts) {
        Uri uri = getPartUri(libraryBuilder.importUri, part);
        if (libraryBuilders.containsKey(uri)) {
          neighbors.add(uri);
        }
      }
    }
    return neighbors;
  }

  @override
  Iterable<Uri> neighborsOf(Uri vertex) =>
      _neighborsCache[vertex] ??= _computeNeighborsOf(vertex);
}
