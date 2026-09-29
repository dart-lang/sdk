// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Source transformer to shadow unexposed DDM host libraries.
///
/// When a dynamic module depends on a library that is present in the host
/// application's outline/dill summaries, but not exposed in
/// `dynamic_interface.yaml`, this tool rewrites directives and generates
/// shadowed source files in an overlay directory so they are compiled from
/// source inside the module rather than resolving to host outlines.
///
/// Note that the shadowing is done on the library level: if a library has
/// some exposed and some unexposed exports, the entire library is not
/// shadowed.
library;

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:package_config/package_config.dart';

import 'directive_extractor.dart';
import 'exposed_libraries_collector.dart';
import 'shadow_options.dart';
import 'uris.dart';

/// Transformer that shadows unexposed host libraries in a dynamic module.
///
/// Traverses the entrypoint script and its directives and writes renamed
/// libraries to the output directory.
class SourceShadowTransformer {
  final void Function(String)? logger;
  final ShadowOptions options;
  final FileWriter fileWriter;

  SourceShadowTransformer(
    this.options, {
    this.logger,
    required this.fileWriter,
  });

  /// Executes the transformation.
  Future<void> transform() async {
    final packageConfig = PackageConfig.parseString(
      await _read(options.packagesUri),
      options.packagesUri,
    );

    final exposedLibraries = await collectExposedLibraries(
      dynamicInterfaceUri: FileSystemUri(options.dynamicInterfaceUri),
      frontendFs: options.frontendFs,
      packageConfig: packageConfig,
      enableRelativeDynamicInterfaceLibraries:
          options.enableRelativeDynamicInterfaceLibraries,
    );

    logger?.call('exposedLibraries: $exposedLibraries');

    await _traverse(packageConfig, exposedLibraries);
  }

  Future<String> _read(Uri uri) =>
      options.frontendFs.entityForUri(uri).readAsString();

  Future<void> _traverse(
    PackageConfig packageConfig,
    Set<LibraryUri> exposedLibraries,
  ) async {
    // Traverse import, export, and part directives starting from the entrypoint
    // script to discover all libraries to shadow.
    //
    // All non-host files (entrypoint, internal module files, and unexposed
    // external packages) are uniformly shadowed with the prefix. Directives
    // pointing to unexposed libraries are rewritten to shadowed filenames, and
    // the shadowed files are written to the output directory.

    // Visited URIs and the queue are package: URIs for libraries belonging to
    // packages in the package config, and physical URIs for other URIs.
    final visitedUris = <LibraryUri>{};

    final entrypointLibraryUri = LibraryUri(options.scriptUri);
    final queue = Queue<LibraryUri>.of([entrypointLibraryUri]);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final isEntrypoint = current == entrypointLibraryUri;

      if (!visitedUris.add(current)) continue;

      final fileUri = current.expand(packageConfig);
      if (fileUri == null) {
        // Assume all transitively reachable packages should be in the package
        // config.
        throw ArgumentError('Cannot resolve package URI $current');
      }

      final entity = options.frontendFs.entityForUri(fileUri.value);
      if (!await entity.exists()) {
        throw ArgumentError('$fileUri does not exist');
      }

      var content = await entity.readAsString();

      // Sort directives by offset in descending order to ensure correct
      // replacement when rewriting the file.
      final directives = extractDirectives(content)
          .sorted((a, b) => b.offset.compareTo(a.offset));

      for (final directive in directives) {
        final literalUri = Uri.parse(directive.uri);

        // Never shadow `dart:` URIs.
        if (literalUri.isScheme('dart')) {
          continue;
        }

        final enableRelativeImports =
            !isEntrypoint || options.enableRelativeEntrypointScriptDirectives;

        if (!literalUri.hasScheme && !enableRelativeImports) {
          throw StateError(
            'Relative import `${directive.uri}` is not supported'
            ' for this entrypoint script.',
          );
        }

        final resolvedUri = current.resolve(literalUri);
        // Skip exposed libraries.
        if (exposedLibraries.contains(resolvedUri)) {
          continue;
        }

        // Shadow the directive for unexposed dependencies.
        final newLiteralUri = _shadowUri(literalUri);
        content = rewriteDirective(content, directive, newLiteralUri);
        queue.add(resolvedUri);
      }

      final destinationUri = FileSystemUri(_shadowUri(fileUri.value));

      await _writeToOutputDir(destinationUri, content);
    }
  }

  Uri _shadowUri(Uri uri) {
    if (uri.pathSegments.isEmpty) return uri;
    final [...precedingPathSegments, lastSegment] = uri.pathSegments;
    return uri.replace(
      pathSegments: [
        ...precedingPathSegments,
        '${options.prefix}_$lastSegment',
      ],
    );
  }

  Future<void> _writeToOutputDir(FileSystemUri uri, String content) async {
    final relativePath = uri.value.path.replaceFirst(RegExp(r'^/+'), '');
    final physicalUri = options.outputDir.resolve(relativePath);
    await fileWriter.call(physicalUri, content);
  }
}

/// Abstracts writing a file to a URI.
typedef FileWriter = Future<void> Function(Uri uri, String content);

/// Transforms module sources to shadow unexposed host dependencies.
Future<void> shadowSources(
  ShadowOptions options, {
  required FileWriter fileWriter,
  void Function(String)? logger,
}) => SourceShadowTransformer(
  options,
  fileWriter: fileWriter,
  logger: logger,
).transform();
