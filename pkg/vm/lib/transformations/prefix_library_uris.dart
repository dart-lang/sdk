// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

Component prefixLibraryUris(
  Component component,
  Set<Library> loadedLibraries,
  String libraryUrisPrefix,
) {
  if (libraryUrisPrefix.isEmpty) {
    return component;
  }
  final prefixSegments = libraryUrisPrefix.split('/');
  final importUriReplacements = <Uri, Uri>{};

  for (final lib in component.libraries) {
    // Skip libraries that come from the host app or the SDK.
    if (loadedLibraries.contains(lib)) {
      continue;
    }
    final newImportUri = prefixUri(lib.importUri, prefixSegments);
    importUriReplacements[lib.importUri] = newImportUri;
    lib.importUri = newImportUri;
  }

  // Update import uris in sources.
  final allSourceFileUris = component.uriToSource.keys.toSet();
  for (final fileUri in allSourceFileUris) {
    final source = component.uriToSource[fileUri]!;
    final importUriReplacement = importUriReplacements[source.importUri];
    if (importUriReplacement == null) {
      continue;
    }

    // Rewrite the source with the new import URI.
    component.uriToSource[fileUri] =
        Source(
            source.lineStarts,
            source.source,
            importUriReplacement,
            source.fileUri,
          )
          ..cachedText = source.cachedText
          ..constantCoverageConstructors = source.constantCoverageConstructors;
  }

  return component;
}

Uri prefixUri(Uri uri, List<String> prefixSegments) {
  if (uri.scheme == 'package') {
    // For package URIs, the first segment is dot-separated package path, so
    // we prepend the prefix to the first segment.
    final pathSegments = uri.pathSegments.toList();
    pathSegments[0] = [...prefixSegments, pathSegments.first].join('.');
    return uri.replace(pathSegments: pathSegments);
  }

  // For other schemes, we just prepend the prefix to the path segments.
  return uri.replace(pathSegments: prefixSegments.followedBy(uri.pathSegments));
}
