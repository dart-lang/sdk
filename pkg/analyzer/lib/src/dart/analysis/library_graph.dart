// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart'
    as graph
    show DependencyWalker, Node;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:collection/collection.dart';

/// Ensure that the `FileState._libraryCycle` for the [file] and anything it
/// depends on is computed.
void computeLibraryCycle(
  bool withFineDependencies,
  Uint32List salt,
  LibraryFileKind file,
) {
  var libraryWalker = _LibraryWalker(withFineDependencies, salt);
  libraryWalker.walk(libraryWalker.getNode(file));
}

/// Information about libraries that reference each other, so form a cycle.
class LibraryCycle {
  static int _nextId = 0;
  final int id = _nextId++;

  final bool withFineDependencies;

  /// The libraries that belong to this cycle.
  final List<LibraryFileKind> libraries;

  /// The URIs of [libraries].
  final Set<Uri> libraryUris;

  /// The library cycles that this cycle references directly.
  final Set<LibraryCycle> directDependencies;

  /// The cycles that use this cycle, used to [dispose] transitively.
  final List<LibraryCycle> directUsers = [];

  /// The transitive API signature of this cycle.
  ///
  /// It is based on the API signatures of all files of the [libraries], and
  /// API signatures of the cycles that the [libraries] reference directly.
  /// So, indirectly it is based on API signatures of the transitive closure
  /// of all files that [libraries] reference.
  final String apiSignature;

  /// The signature to find linked summary bundles when [withFineDependencies]
  /// is `true`.
  ///
  /// It is based on the URIs and paths of the files of this cycle. It is *not*
  /// based on API signatures, because we want to be able to find previous
  /// manifests to compare new elements against it, to keep IDs for not
  /// affected element.
  final String manifestSignature;

  /// The non-transitive API signature of this cycle.
  ///
  /// It is based on the API signatures of all files of the [libraries]. But
  /// it does *not* include API signatures of dependencies. We want to know
  /// when we have to relink this bundle. And the idea of the fine grained
  /// dependencies is that library cycles depend only on a small number of
  /// elements from their dependency cycles, not on all of them.
  final String nonTransitiveApiSignature;

  LibraryCycle({
    required this.withFineDependencies,
    required this.libraries,
    required this.libraryUris,
    required this.directDependencies,
    required this.apiSignature,
    required this.manifestSignature,
    required this.nonTransitiveApiSignature,
  }) {
    for (var directDependency in directDependencies) {
      directDependency.directUsers.add(this);
    }
  }

  /// The key of the linked libraries in the byte store.
  String get linkedKey {
    if (withFineDependencies) {
      return '$manifestSignature.linked';
    } else {
      return '$apiSignature.linked';
    }
  }

  /// Dispose this cycle and any cycles that directly or indirectly use it.
  ///
  /// Practically this means that we clear the library cycle in all the
  /// [libraries] that share this [LibraryCycle] instance.
  void dispose() {
    for (var library in libraries) {
      library.internal_setLibraryCycle(null);
    }
    for (var user in directUsers.toList()) {
      user.dispose();
    }
    for (var directDependency in directDependencies) {
      directDependency.directUsers.remove(this);
    }
  }

  @override
  String toString() {
    return '[$id][${libraries.join(', ')}]';
  }
}

/// Node in [_LibraryWalker].
class _LibraryNode extends graph.Node<_LibraryNode> {
  final _LibraryWalker walker;
  final LibraryFileKind kind;

  _LibraryNode(this.walker, this.kind);

  @override
  bool get isEvaluated => kind.internal_libraryCycle != null;

  @override
  List<_LibraryNode> computeDependencies() {
    var referencedLibraries = kind.fileKinds
        .map((fileKind) {
          return [
            ...fileKind.libraryImports.whereType<LibraryImportWithFile>().map(
              (import) => import.importedLibrary,
            ),
            ...fileKind.libraryExports.whereType<LibraryExportWithFile>().map(
              (export) => export.exportedLibrary,
            ),
          ];
        })
        .flattenedToList
        .nonNulls
        .toSet();

    return referencedLibraries.map(walker.getNode).toList();
  }

  @override
  String toString() {
    return 'LibraryNode($kind)';
  }
}

/// Helper that organizes dependencies of a library into topologically
/// sorted [LibraryCycle]s.
class _LibraryWalker extends graph.DependencyWalker<_LibraryNode> {
  final bool withFineDependencies;
  final Uint32List _salt;
  final Map<LibraryFileKind, _LibraryNode> nodesOfFiles = {};

  _LibraryWalker(this.withFineDependencies, this._salt);

  @override
  void evaluate(_LibraryNode v) {
    evaluateScc([v]);
  }

  @override
  void evaluateScc(List<_LibraryNode> scc) {
    var apiSignature = ApiSignature();
    apiSignature.addUint32List(_salt);

    // Sort libraries to produce stable signatures.
    scc.sort((first, second) {
      var firstPath = first.kind.file.path;
      var secondPath = second.kind.file.path;
      return firstPath.compareTo(secondPath);
    });

    // Append direct referenced cycles.
    var directDependencies = <LibraryCycle>{};
    for (var node in scc) {
      _appendDirectlyReferenced(
        directDependencies,
        apiSignature,
        graph.Node.getDependencies(node),
      );
    }

    // Fill the cycle with libraries.
    var libraries = <LibraryFileKind>[];
    var libraryUris = <Uri>{};
    for (var node in scc) {
      var file = node.kind.file;
      libraries.add(node.kind);
      libraryUris.add(file.uri);

      apiSignature.addLanguageVersion(file.packageLanguageVersion);
      apiSignature.addString(file.uriStr);

      var libraryFiles = node.kind.files;

      apiSignature.addInt(libraryFiles.length);
      for (var file in libraryFiles) {
        apiSignature.addBool(file.exists);
        apiSignature.addBytes(file.apiSignature);
      }
    }

    String manifestSignature;
    String nonTransitiveApiSignature;
    {
      var manifestBuilder = ApiSignature();
      var apiSignatureBuilder = ApiSignature();
      manifestBuilder.addUint32List(_salt);
      var sortedFiles = libraries
          .expand((library) => library.files)
          .sortedBy((file) => file.path);
      for (var file in sortedFiles) {
        manifestBuilder.addString(file.path);
        manifestBuilder.addString(file.uriStr);
        apiSignatureBuilder.addBytes(file.apiSignature);
      }
      manifestSignature = manifestBuilder.toHex();
      nonTransitiveApiSignature = apiSignatureBuilder.toHex();
    }

    // Create the LibraryCycle instance for the cycle.
    var cycle = LibraryCycle(
      withFineDependencies: withFineDependencies,
      libraries: libraries.toFixedList(),
      libraryUris: libraryUris,
      directDependencies: directDependencies,
      apiSignature: apiSignature.toHex(),
      manifestSignature: manifestSignature,
      nonTransitiveApiSignature: nonTransitiveApiSignature,
    );

    // Set the instance into the libraries.
    for (var node in scc) {
      node.kind.internal_setLibraryCycle(cycle);
    }
  }

  _LibraryNode getNode(LibraryFileKind file) {
    return nodesOfFiles.putIfAbsent(file, () => _LibraryNode(this, file));
  }

  void _appendDirectlyReferenced(
    Set<LibraryCycle> directDependencies,
    ApiSignature apiSignature,
    List<_LibraryNode> directlyReferenced,
  ) {
    apiSignature.addInt(directlyReferenced.length);
    for (var referencedLibrary in directlyReferenced) {
      var referencedCycle = referencedLibrary.kind.internal_libraryCycle;

      // We get null when the library is a part of the cycle being build.
      if (referencedCycle == null) continue;

      if (directDependencies.add(referencedCycle)) {
        apiSignature.addString(referencedCycle.apiSignature);
      }
    }
  }
}
