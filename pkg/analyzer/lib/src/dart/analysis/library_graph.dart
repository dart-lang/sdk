// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart' as graph
    show DependencyWalker, Node;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:collection/collection.dart';

/// Ensure that the [FileState.libraryCycle] for the [file] and anything it
/// depends on is computed.
void computeLibraryCycle(Uint32List salt, FileState file) {
  var libraryWalker = _LibraryWalker(salt);
  libraryWalker.walk(libraryWalker.getNode(file));
}

/// Information about libraries that reference each other, so form a cycle.
class LibraryCycle {
  /// The libraries that belong to this cycle.
  final List<FileState> libraries;

  /// The library cycles that this cycle references directly.
  final Set<LibraryCycle> directDependencies;

  /// The cycles that use this cycle, used to [invalidate] transitively.
  final List<LibraryCycle> _directUsers = [];

  /// The transitive API signature of this cycle.
  ///
  /// It is based on the API signatures of all files of the [libraries], and
  /// API signatures of the cycles that the [libraries] reference directly.
  /// So, indirectly it is based on API signatures of the transitive closure
  /// of all files that [libraries] reference.
  String apiSignature;

  /// The transitive implementation signature of this cycle.
  ///
  /// It is based on the full code signatures of all files of the [libraries],
  /// and full code signatures of the cycles that the [libraries] reference
  /// directly. So, indirectly it is based on full code signatures of the
  /// transitive closure of all files that [libraries] reference.
  ///
  /// Usually, when a library is imported we need its [apiSignature], because
  /// its API is all we can see from outside. But if the library contains
  /// a macro, and we use it, we run full code of the macro defining library,
  /// potentially executing every method body of the transitive closure of
  /// the libraries imported by the macro defining library. So, the resulting
  /// library (that imports a macro defining library) API signature must
  /// include [implSignature] of the macro defining library.
  String implSignature;

  late final bool hasMacroClass = () {
    for (final library in libraries) {
      for (final file in library.libraryFiles) {
        if (file.unlinked2.macroClasses.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }();

  LibraryCycle({
    required this.libraries,
    required this.directDependencies,
    required this.apiSignature,
    required this.implSignature,
  }) {
    for (var directDependency in directDependencies) {
      directDependency._directUsers.add(this);
    }
  }

  /// Invalidate this cycle and any cycles that directly or indirectly use it.
  ///
  /// Practically invalidation means that we clear the library cycle in all the
  /// [libraries] that share this [LibraryCycle] instance.
  void invalidate() {
    for (var library in libraries) {
      library.internal_setLibraryCycle(null);
    }
    for (var user in _directUsers.toList()) {
      user.invalidate();
    }
    for (var directDependency in directDependencies) {
      directDependency._directUsers.remove(this);
    }
  }

  @override
  String toString() {
    return '[${libraries.join(', ')}]';
  }
}

/// Node in [_LibraryWalker].
class _LibraryNode extends graph.Node<_LibraryNode> {
  final _LibraryWalker walker;
  final FileState file;

  _LibraryNode(this.walker, this.file);

  @override
  bool get isEvaluated => file.internal_libraryCycle != null;

  @override
  List<_LibraryNode> computeDependencies() {
    return file.directReferencedLibraries.map(walker.getNode).toList();
  }
}

/// Helper that organizes dependencies of a library into topologically
/// sorted [LibraryCycle]s.
class _LibraryWalker extends graph.DependencyWalker<_LibraryNode> {
  final Uint32List _salt;
  final Map<FileState, _LibraryNode> nodesOfFiles = {};

  _LibraryWalker(this._salt);

  @override
  void evaluate(_LibraryNode v) {
    evaluateScc([v]);
  }

  @override
  void evaluateScc(List<_LibraryNode> scc) {
    var apiSignature = ApiSignature();
    var implSignature = ApiSignature();
    apiSignature.addUint32List(_salt);
    implSignature.addUint32List(_salt);

    // Sort libraries to produce stable signatures.
    scc.sort((first, second) {
      var firstPath = first.file.path;
      var secondPath = second.file.path;
      return firstPath.compareTo(secondPath);
    });

    // Append direct referenced cycles.
    var directDependencies = <LibraryCycle>{};
    for (var node in scc) {
      var file = node.file;
      _appendDirectlyReferenced(
        directDependencies,
        apiSignature,
        implSignature,
        file.directReferencedLibraries.whereNotNull().toList(),
      );
    }

    // Fill the cycle with libraries.
    var libraries = <FileState>[];
    for (var node in scc) {
      libraries.add(node.file);

      apiSignature.addLanguageVersion(node.file.packageLanguageVersion);
      apiSignature.addString(node.file.uriStr);

      implSignature.addLanguageVersion(node.file.packageLanguageVersion);
      implSignature.addString(node.file.uriStr);

      apiSignature.addInt(node.file.libraryFiles.length);
      for (var file in node.file.libraryFiles) {
        apiSignature.addBool(file.exists);
        apiSignature.addBytes(file.apiSignature);
      }

      implSignature.addInt(node.file.libraryFiles.length);
      for (var file in node.file.libraryFiles) {
        implSignature.addBool(file.exists);
        implSignature.addString(file.contentHash);
      }
    }

    // Create the LibraryCycle instance for the cycle.
    var cycle = LibraryCycle(
      libraries: libraries,
      directDependencies: directDependencies,
      apiSignature: apiSignature.toHex(),
      implSignature: implSignature.toHex(),
    );

    // Set the instance into the libraries.
    for (var node in scc) {
      node.file.internal_setLibraryCycle(cycle);
    }
  }

  _LibraryNode getNode(FileState file) {
    return nodesOfFiles.putIfAbsent(file, () => _LibraryNode(this, file));
  }

  void _appendDirectlyReferenced(
    Set<LibraryCycle> directDependencies,
    ApiSignature apiSignature,
    ApiSignature implSignature,
    List<FileState> directlyReferenced,
  ) {
    apiSignature.addInt(directlyReferenced.length);
    implSignature.addInt(directlyReferenced.length);
    for (var referencedLibrary in directlyReferenced) {
      var referencedCycle = referencedLibrary.internal_libraryCycle;

      // We get null when the library is a part of the cycle being build.
      if (referencedCycle == null) continue;

      if (directDependencies.add(referencedCycle)) {
        apiSignature.addString(
          referencedCycle.hasMacroClass
              ? referencedCycle.implSignature
              : referencedCycle.apiSignature,
        );
        implSignature.addString(referencedCycle.implSignature);
      }
    }
  }
}
