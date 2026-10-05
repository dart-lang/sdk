// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities for reading and parsing dynamic interface specifications.
library;

import 'dart:collection';

import 'package:front_end/src/api_unstable/vm.dart'
    as front_end
    show FileSystem;
import 'package:front_end/src/kernel/dynamic_module_validator.dart'
    show DynamicInterfaceYamlFile;
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:package_config/package_config.dart';

import 'directive_extractor.dart';
import 'uris.dart';

/// Collector that finds all exposed libraries in a dynamic interface.
class ExposedLibrariesCollector {
  final front_end.FileSystem frontendFs;
  final FileSystemUri dynamicInterfaceUri;
  final PackageConfig packageConfig;
  final bool enableRelativeDynamicInterfaceLibraries;

  final _exposedLibraries = <LibraryUri>{};

  ExposedLibrariesCollector({
    required this.frontendFs,
    required this.dynamicInterfaceUri,
    required this.packageConfig,
    required this.enableRelativeDynamicInterfaceLibraries,
  });

  /// Collects and returns the set of all exposed library URIs.
  Future<Set<LibraryUri>> collect() async {
    final content = await frontendFs
        .entityForUri(dynamicInterfaceUri.value)
        .readAsString();

    final dynamicInterface = DynamicInterfaceYamlFile(content);
    if (dynamicInterface.isEmpty) {
      return <LibraryUri>{};
    }

    final (partialLibraries, wholeLibraries) = findInterfaceLibraries(
      dynamicInterface: dynamicInterface,
    );

    await traverse(wholeLibraries);

    // Now add partial libraries to the exposed libraries.
    _exposedLibraries.addAll(partialLibraries);
    return _exposedLibraries;
  }

  /// Resolves a library string to an import URI.
  ///
  /// For files inside a package, the URI will be a package URI, e.g.
  /// `package:foo/bar.dart`. For files outside of a package, the URI will be a
  /// file system / or abstract file system URI, e.g.
  /// `file:///path/to/file.dart` or `multi-root:///path/to/file.dart`.
  ///
  /// Returns `null` if the library cannot be resolved, or if it is a Dart SDK
  /// library.
  @visibleForTesting
  LibraryUri? resolveLibraryUri(
    String library,
    LibraryUri currentUri,
    bool enableRelativeUris,
  ) {
    final literalUri = Uri.parse(library);

    if (literalUri.hasScheme &&
        !const {'package', 'dart'}.contains(literalUri.scheme)) {
      throw StateError(
        'Unsupported library uri scheme: `${literalUri.scheme}` in `$literalUri`',
      );
    }

    if (!literalUri.hasScheme && !enableRelativeUris) {
      throw StateError('Relative library uri `$literalUri` is not supported.');
    }

    final resolved = currentUri.resolve(literalUri);

    if (resolved.isScheme('dart')) {
      // Skip Dart SDK libraries.
      return null;
    }

    return resolved;
  }

  /// Returns a set of resolved library exports.
  Future<Set<LibraryUri>> _expandLibrary(LibraryUri libraryUri) async {
    final fileUri = libraryUri.expand(packageConfig);
    if (fileUri == null) {
      // If we cannot resolve the package URI, we assume it's a host dependency
      // which is not a dynamic module dependency, so it is safe to ignore.
      return const {};
    }
    final entity = frontendFs.entityForUri(fileUri.value);
    if (!await entity.exists()) {
      // A resolved file may still be missing if it belongs to a host target
      // within a shared package directory that is not a dependency of the
      // dynamic module, which may happen in google3.
      return const {};
    }
    final content = await entity.readAsString();
    final directives = extractDirectives(content);
    final exports = <LibraryUri>{};
    for (final directive in directives) {
      if (!directive.isExport) continue;

      final resolvedUri = resolveLibraryUri(directive.uri, libraryUri, true);
      if (resolvedUri != null) {
        exports.add(resolvedUri);
      }
    }

    return exports;
  }

  /// Finds all exposed libraries in the dynamic interface specification.
  ///
  /// Operates on the dynamic interface YAML file: returns all libraries as
  /// URIs and classifies them as whole (no extra element restrictions) or
  /// partial.
  @visibleForTesting
  (Set<LibraryUri> partialLibraries, Set<LibraryUri> wholeLibraries)
  findInterfaceLibraries({required DynamicInterfaceYamlFile dynamicInterface}) {
    final partialLibraries = <LibraryUri>{};
    final wholeLibraries = <LibraryUri>{};

    if (dynamicInterface.isEmpty) {
      return (partialLibraries, wholeLibraries);
    }

    final allItems = [
      dynamicInterface.extendable,
      dynamicInterface.canBeOverridden,
      dynamicInterface.callable,
      dynamicInterface.canBeUsedAsType,
      dynamicInterface.dynamicallyCallable,
    ].nonNulls.expand((section) => section);

    for (final item in allItems) {
      final itemMap = item as Map;
      final lib = itemMap['library'] as String;

      // Only whole library nodes (without member or class restrictions)
      // have their exported declarations expanded in Kernel validation
      // (see _expandNode and findNodes in dynamic_module_validator.dart).
      final isWholeLibrary = itemMap.keys.toSet().intersection(const {
        'class',
        'member',
        'extension',
        'extension_type',
      }).isEmpty;

      // We resolve libraries in the dynamic interface relative to the dynamic
      // interface URI, so translating the file system URI to a library URI
      // for bootstrapping the resolution process.
      final currentLibraryUri = LibraryUri(dynamicInterfaceUri.value);

      final resolved = resolveLibraryUri(
        lib,
        currentLibraryUri,
        enableRelativeDynamicInterfaceLibraries,
      );

      if (resolved == null) {
        continue;
      }

      if (isWholeLibrary) {
        wholeLibraries.add(resolved);
      } else {
        partialLibraries.add(resolved);
      }
    }
    return (partialLibraries, wholeLibraries);
  }

  /// Transitively expands `export` directives of exposed whole libraries.
  @visibleForTesting
  Future<void> traverse(Set<LibraryUri> libraries) async {
    final queue = Queue<LibraryUri>.of(libraries);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (!_exposedLibraries.add(current)) {
        continue;
      }
      queue.addAll(await _expandLibrary(current));
    }
  }
}

/// Collects all libraries exposed by the dynamic interface.
///
/// Parses the dynamic interface YAML file at [dynamicInterfacePath] and
/// transitively expands `export` directives of exposed whole libraries
/// (e.g. `package:flutter/material.dart`).
Future<Set<LibraryUri>> collectExposedLibraries({
  required FileSystemUri dynamicInterfaceUri,
  required front_end.FileSystem frontendFs,
  required PackageConfig packageConfig,
  bool enableRelativeDynamicInterfaceLibraries = false,
}) async => ExposedLibrariesCollector(
  dynamicInterfaceUri: dynamicInterfaceUri,
  frontendFs: frontendFs,
  packageConfig: packageConfig,
  enableRelativeDynamicInterfaceLibraries:
      enableRelativeDynamicInterfaceLibraries,
).collect();
