// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/util/graph.dart';

import 'package:vm/kernel_front_end.dart';
import 'package:front_end/src/api_unstable/vm.dart' show FileSystem;

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
    this.mainUri, [
    this.packagesUri,
    this.fileSystem,
  ]);

  /// The Component that is being compiled.
  ///
  /// On incremental compiles, this will only contain the invalidated
  /// lbraries.
  final Component component;

  /// The main URI for thiis application.
  final Uri mainUri;

  /// The URI of the .packages file.
  final Uri packagesUri;

  /// The filesystem instance for resolving files.
  final FileSystem fileSystem;

  /// The set of libraries for each module URI.
  ///
  /// This is populated after calling [computeModules] once.
  final Map<Uri, List<Library>> modules = <Uri, List<Library>>{};

  /// The module URI for each library file URI.
  ///
  /// This is populated after calling [computeModules] once.
  final Map<Uri, Uri> moduleAssignment = <Uri, Uri>{};

  /// Compute the strongly connected components for the current program.
  ///
  /// Throws an [Exception] if [mainUri] cannot be located in the given
  /// component.
  Future<void> computeModules() async {
    assert(modules.isEmpty);
    if (component.libraries.isEmpty) {
      return;
    }
    Uri entrypointFileUri = mainUri;
    if (!entrypointFileUri.isScheme('file')) {
      entrypointFileUri = await asFileUri(fileSystem,
          await _convertToFileUri(fileSystem, entrypointFileUri, packagesUri));
    }
    if (entrypointFileUri == null || !entrypointFileUri.isScheme('file')) {
      throw Exception(
          'Unable to map ${entrypointFileUri} back to file scheme.');
    }

    // If we don't have a file uri, just use the first library in the
    // component.
    Library entrypoint = component.libraries.firstWhere(
        (Library library) => library.fileUri == entrypointFileUri,
        orElse: () => null);

    if (entrypoint == null) {
      throw Exception(
          'Could not find entrypoint ${entrypointFileUri} in Component.');
    }

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

  // Convert package URI to file URI if it is inside one of the packages.
  Future<Uri> _convertToFileUri(
      FileSystem fileSystem, Uri uri, Uri packagesUri) async {
    if (uri == null || uri.scheme != 'package') {
      return uri;
    }
    // Convert virtual URI to a real file URI.
    // String uriString = (await asFileUri(fileSystem, uri)).toString();
    List<String> packages;
    try {
      packages =
          await File((await asFileUri(fileSystem, packagesUri)).toFilePath())
              .readAsLines();
    } on IOException {
      // Can't read packages file - silently give up.
      return uri;
    }
    // package:x.y/main.dart -> file:///a/b/x/y/main.dart
    for (var line in packages) {
      if (line.isEmpty || line.startsWith("#")) {
        continue;
      }

      final colon = line.indexOf(':');
      if (colon == -1) {
        continue;
      }
      final packageName = line.substring(0, colon);
      if (!uri.path.startsWith(packageName)) {
        continue;
      }
      String packagePath;
      try {
        packagePath = (await asFileUri(
                fileSystem, packagesUri.resolve(line.substring(colon + 1))))
            .toString();
      } on FileSystemException {
        // Can't resolve package path.
        continue;
      }
      return Uri.parse(
          '$packagePath${uri.path.substring(packageName.length + 1)}');
    }
    return uri;
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
