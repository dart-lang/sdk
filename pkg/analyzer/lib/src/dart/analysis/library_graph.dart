// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;

/// Ensure that the [FileState.libraryCycle] for the [file] and anything it
/// depends on is computed.
void computeLibraryCycle(Uint32List salt, FileState file) {
  var libraryWalker = _LibraryWalker(salt);
  libraryWalker.walk(libraryWalker.getNode(file));
}

/// Information about libraries that reference each other, so form a cycle.
class LibraryCycle {
  final int id = fileObjectId++;

  /// The libraries that belong to this cycle.
  final List<FileState> libraries = [];

  /// The library cycles that this cycle references directly.
  final Set<LibraryCycle> directDependencies = <LibraryCycle>{};

  /// The cycles that use this cycle, used to [invalidate] transitively.
  final List<LibraryCycle> _directUsers = [];

  /// The transitive signature of this cycle.
  ///
  /// It is based on the API signatures of all files of the [libraries], and
  /// transitive signatures of the cycles that the [libraries] reference
  /// directly.  So, indirectly it is based on the transitive closure of all
  /// files that [libraries] reference (but we don't compute these files).
  String transitiveSignature;

  /// The map from a library in [libraries] to its transitive signature.
  ///
  /// It is almost the same as [transitiveSignature], but is also based on
  /// the URI of this specific library.  Currently we store each linked library
  /// with its own key, so we need unique keys.  However practically we never
  /// can use just *one* library of a cycle, we always use the whole cycle.
  ///
  /// TODO(scheglov) Switch to loading the whole cycle maybe?
  final Map<FileState, String> transitiveSignatures = {};

  LibraryCycle();

  LibraryCycle.external() : transitiveSignature = '<external>';

  bool get isUnresolvedFile {
    return libraries.length == 1 && libraries[0].isUnresolved;
  }

  /// Invalidate this cycle and any cycles that directly or indirectly use it.
  ///
  /// Practically invalidation means that we clear the library cycle in all the
  /// [libraries] that share this [LibraryCycle] instance.
  void invalidate() {
    for (var library in libraries) {
      library.internal_setLibraryCycle(null, null);
    }
    for (var user in _directUsers) {
      user.invalidate();
    }
    _directUsers.clear();
  }

  @override
  String toString() {
    return '[[id: $id] ' + libraries.join(', ') + ']';
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
    var cycle = LibraryCycle();

    var signature = ApiSignature();
    signature.addUint32List(_salt);

    // Sort libraries to produce stable signatures.
    scc.sort((first, second) {
      var firstPath = first.file.path;
      var secondPath = second.file.path;
      return firstPath.compareTo(secondPath);
    });

    // Append direct referenced cycles.
    for (var node in scc) {
      var file = node.file;
      _appendDirectlyReferenced(cycle, signature, file.importedFiles);
      _appendDirectlyReferenced(cycle, signature, file.exportedFiles);
    }

    // Fill the cycle with libraries.
    for (var node in scc) {
      cycle.libraries.add(node.file);

      signature.addLanguageVersion(node.file.packageLanguageVersion);
      signature.addString(node.file.uriStr);

      signature.addInt(node.file.libraryFiles.length);
      for (var file in node.file.libraryFiles) {
        signature.addBool(file.exists);
        signature.addBytes(file.apiSignature);
      }
    }

    // Compute the general library cycle signature.
    cycle.transitiveSignature = signature.toHex();

    // Compute library specific signatures.
    for (var node in scc) {
      var librarySignatureBuilder = ApiSignature()
        ..addString(node.file.uriStr)
        ..addString(cycle.transitiveSignature);
      var librarySignature = librarySignatureBuilder.toHex();

      node.file.internal_setLibraryCycle(
        cycle,
        librarySignature,
      );
    }
  }

  _LibraryNode getNode(FileState file) {
    return nodesOfFiles.putIfAbsent(file, () => _LibraryNode(this, file));
  }

  void _appendDirectlyReferenced(
    LibraryCycle cycle,
    ApiSignature signature,
    List<FileState> directlyReferenced,
  ) {
    signature.addInt(directlyReferenced.length);
    for (var referencedLibrary in directlyReferenced) {
      var referencedCycle = referencedLibrary.internal_libraryCycle;

      // We get null when the library is a part of the cycle being build.
      if (referencedCycle == null) continue;

      if (cycle.directDependencies.add(referencedCycle)) {
        referencedCycle._directUsers.add(cycle);
        signature.addString(referencedCycle.transitiveSignature);
      }
    }
  }
}
