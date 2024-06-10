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
  final Map<Uri, CompilationUnit> compilationUnits;

  final Map<Uri, List<Uri>> _neighborsCache = {};

  BuilderGraph(this.compilationUnits);

  @override
  Iterable<Uri> get vertices => compilationUnits.keys;

  List<Uri> _computeNeighborsOf(Uri vertex) {
    List<Uri> neighbors = [];
    CompilationUnit? compilationUnit = compilationUnits[vertex];
    if (compilationUnit == null) {
      throw "Library not found: $vertex";
    }
    if (compilationUnit is SourceLibraryBuilder) {
      for (Import import in compilationUnit.imports) {
        // 'imported' can be null for fake imports, such as dart-ext:.
        if (import.imported != null) {
          Uri uri = import.imported!.importUri;
          if (compilationUnits.containsKey(uri)) {
            neighbors.add(uri);
          }
        }
      }
      for (Export export in compilationUnit.exports) {
        Uri uri = export.exported.importUri;
        if (compilationUnits.containsKey(uri)) {
          neighbors.add(uri);
        }
      }
      for (Part part in compilationUnit.parts) {
        Uri uri = part.compilationUnit.importUri;
        if (compilationUnits.containsKey(uri)) {
          neighbors.add(uri);
        }
      }
    } else if (compilationUnit is DillLibraryBuilder) {
      // Imports and exports
      for (LibraryDependency dependency
          in compilationUnit.library.dependencies) {
        Uri uri = dependency.targetLibrary.importUri;
        if (compilationUnits.containsKey(uri)) {
          neighbors.add(uri);
        }
      }

      // Parts
      for (LibraryPart part in compilationUnit.library.parts) {
        Uri uri = getPartUri(compilationUnit.importUri, part);
        if (compilationUnits.containsKey(uri)) {
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
