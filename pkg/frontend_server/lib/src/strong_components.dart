// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/util/graph.dart';

/// Compute the strongly connected components for JavaScript compilation.
///
/// Implements a Path-based strong component algorithm.
/// See https://en.wikipedia.org/wiki/Path-based_strong_component_algorithm
///
/// The file URI for each library is used as an identifier for the module
/// name. [moduleAssignment] will be populated with a mapping of library URI to
/// module name, while [modules] will be populated with a mapping of module
/// name to library set.
///
/// JavaScript import semantics do not permit circular imports in the same
/// manner that Dart does. When compiling a set of libraries with circular
/// imports, these must be combined into a single JavaScript module.
///
/// On incremental updates, we completely recompute the strongly connected
/// components, but only for the partial component produced.
class StrongComponents {
  StrongComponents(
    this.component,
    this.entrypointFileUri,
  );

  /// The Component that is being compiled.
  ///
  /// On incremental compiles, this will only contain the invalidated
  /// lbraries.
  final Component component;

  /// The file URI containing main for this application.
  final Uri entrypointFileUri;

  /// The set of libraries for each module URI.
  ///
  /// This is populated after calling [computeModules] once.
  final Map<Uri, List<Library>> modules = <Uri, List<Library>>{};

  /// The module URI for each library file URI.
  ///
  /// This is populated after calling [computeModules] once.
  final Map<Uri, Uri> moduleAssignment = <Uri, Uri>{};

  /// Compute the strongly connected components for the current program.
  void computeModules() {
    assert(modules.isEmpty);
    if (component.libraries.isEmpty) {
      return;
    }
    final Library entrypoint = component.libraries
        .firstWhere((Library library) => library.fileUri == entrypointFileUri);
    final List<List<Library>> results =
        computeStrongComponents(_LibraryGraph(entrypoint));
    for (List<Library> component in results) {
      assert(component.length > 0);
      final Uri moduleUri = component.first.fileUri;
      modules[moduleUri] = component;
      for (Library componentLibrary in component) {
        moduleAssignment[componentLibrary.fileUri] = moduleUri;
      }
    }
  }
}

class _LibraryGraph implements Graph<Library> {
  _LibraryGraph(this.library);

  final Library library;

  @override
  Iterable<Library> neighborsOf(Library vertex) {
    return <Library>[
      for (LibraryDependency dependency in vertex.dependencies)
        if (!dependency.targetLibrary.isExternal &&
            dependency.targetLibrary.importUri.scheme != 'dart')
          dependency.targetLibrary
    ];
  }

  @override
  Iterable<Library> get vertices => <Library>[library];
}
