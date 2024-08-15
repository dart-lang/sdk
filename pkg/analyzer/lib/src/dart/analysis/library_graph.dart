// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart' as graph
    show DependencyWalker, Node;
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:collection/collection.dart';

/// Ensure that the [FileState.libraryCycle] for the [file] and anything it
/// depends on is computed.
void computeLibraryCycle(Uint32List salt, LibraryFileKind file) {
  var libraryWalker = _LibraryWalker(salt);
  libraryWalker.walk(libraryWalker.getNode(file));
}

/// Information about libraries that reference each other, so form a cycle.
class LibraryCycle {
  static int _nextId = 0;
  final int id = _nextId++;

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
  final String implSignature;

  /// The transitive macro implementation signature of this cycle.
  ///
  /// It is based on full code signatures of all files that might affect
  /// macro implementation code.
  final String implSignatureMacro;

  late final bool declaresMacroClass = () {
    for (var library in libraries) {
      for (var file in library.files) {
        if (file.unlinked2.macroClasses.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }();

  /// Set to `true` if this library cycle contains code that might be executed
  /// by a macro - declares a macro class itself, or is directly or indirectly
  /// imported into a cycle that declares one.
  bool mightBeExecutedByMacroClass = false;

  /// If a cycle imports a library that declares a macro, then it can have
  /// macro applications, and so macro-generated files.
  late final bool importsMacroClass = () {
    for (var dependency in directDependencies) {
      if (dependency.declaresMacroClass) {
        return true;
      }
    }
    return false;
  }();

  /// Set to `true` if this library cycle [importsMacroClass], and we have
  /// already created macro generated [FileState]s.
  bool hasMacroFilesCreated = false;

  LibraryCycle({
    required this.libraries,
    required this.libraryUris,
    required this.directDependencies,
    required this.apiSignature,
    required this.implSignature,
    required this.implSignatureMacro,
  }) {
    for (var directDependency in directDependencies) {
      directDependency.directUsers.add(this);
    }
  }

  /// The key to store the bundle with multiple libraries, containing
  /// potentially reusable macro generated code for each library.
  String get cachedMacrosKey {
    var builder = ApiSignature();
    builder.addInt(AnalysisDriver.DATA_VERSION);

    builder.addString(implSignatureMacro);

    var sortedLibraries = libraries.sortedBy((l) => l.file.path);
    for (var library in sortedLibraries) {
      builder.addString(library.file.path);
      builder.addString(library.file.uriStr);
    }

    var keyHex = builder.toHex();
    return '$keyHex.macro_results';
  }

  /// The key of the linked libraries in the byte store.
  String get linkedKey => '$apiSignature.linked';

  /// The key of the macro kernel in the byte store.
  String get macroKey => '$implSignature.macro_kernel';

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

  /// Mark this cycle and its dependencies are potentially executed by a macro.
  void markMightBeExecutedByMacroClass() {
    if (!mightBeExecutedByMacroClass) {
      mightBeExecutedByMacroClass = true;
      // Mark each file of the cycle.
      for (var library in libraries) {
        for (var file in library.files) {
          file.mightBeExecutedByMacroClass = true;
        }
      }
      // Recursively mark all dependencies.
      for (var dependency in directDependencies) {
        dependency.markMightBeExecutedByMacroClass();
      }
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
            ...fileKind.libraryImports
                .whereType<LibraryImportWithFile>()
                .map((import) => import.importedLibrary),
            ...fileKind.libraryExports
                .whereType<LibraryExportWithFile>()
                .map((export) => export.exportedLibrary),
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
  final Uint32List _salt;
  final Map<LibraryFileKind, _LibraryNode> nodesOfFiles = {};

  _LibraryWalker(this._salt);

  @override
  void evaluate(_LibraryNode v) {
    evaluateScc([v]);
  }

  @override
  void evaluateScc(List<_LibraryNode> scc) {
    var apiSignature = ApiSignature();
    var implSignature = ApiSignature();
    var implSignature2 = ApiSignature();
    apiSignature.addUint32List(_salt);
    implSignature.addUint32List(_salt);
    implSignature2.addUint32List(_salt);

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
        implSignature,
        implSignature2,
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

      implSignature.addLanguageVersion(file.packageLanguageVersion);
      implSignature.addString(file.uriStr);
      implSignature.addString(Platform.version);

      var libraryFiles = node.kind.files;

      apiSignature.addInt(libraryFiles.length);
      for (var file in libraryFiles) {
        apiSignature.addBool(file.exists);
        apiSignature.addBytes(file.apiSignature);
      }

      implSignature.addInt(libraryFiles.length);
      for (var file in libraryFiles) {
        implSignature.addBool(file.exists);
        implSignature.addString(file.contentHash);
      }
    }

    // Create the LibraryCycle instance for the cycle.
    var cycle = LibraryCycle(
      libraries: libraries.toFixedList(),
      libraryUris: libraryUris,
      directDependencies: directDependencies,
      apiSignature: apiSignature.toHex(),
      implSignature: implSignature.toHex(),
      implSignatureMacro: implSignature2.toHex(),
    );

    if (cycle.declaresMacroClass) {
      cycle.markMightBeExecutedByMacroClass();
    }

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
    ApiSignature implSignature,
    ApiSignature implSignatureMacro,
    List<_LibraryNode> directlyReferenced,
  ) {
    apiSignature.addInt(directlyReferenced.length);
    implSignature.addInt(directlyReferenced.length);
    for (var referencedLibrary in directlyReferenced) {
      var referencedCycle = referencedLibrary.kind.internal_libraryCycle;

      // We get null when the library is a part of the cycle being build.
      if (referencedCycle == null) continue;

      if (directDependencies.add(referencedCycle)) {
        if (referencedCycle.declaresMacroClass) {
          apiSignature.addString(referencedCycle.implSignature);
          implSignatureMacro.addString(referencedCycle.implSignature);
        } else {
          apiSignature.addString(referencedCycle.apiSignature);
        }
        implSignature.addString(referencedCycle.implSignature);
      }
    }
  }
}
