// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:front_end/byte_store.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/src/base/resolve_relative_uri.dart';
import 'package:front_end/src/dependency_walker.dart' as graph;
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:front_end/src/incremental/format.dart';
import 'package:front_end/src/incremental/unlinked_unit.dart';
import 'package:kernel/target/targets.dart';

/// This function is called for each newly discovered file, and the returned
/// [Future] is awaited before reading the file content.
typedef Future<Null> NewFileFn(Uri uri);

/// Information about a file being compiled, explicitly or implicitly.
///
/// It provides a consistent view on its properties.
///
/// The properties are not guaranteed to represent the most recent state
/// of the file system. To update the file to the most recent state, [refresh]
/// should be called.
class FileState {
  final FileSystemState _fsState;

  /// The absolute URI of the file.
  final Uri uri;

  /// The UTF8 bytes of the [uri].
  final List<int> uriBytes;

  /// The resolved URI of the file in the file system.
  final Uri fileUri;

  bool _exists;
  List<int> _content;
  List<int> _contentHash;
  bool _hasMixinApplication;
  List<int> _apiSignature;

  List<FileState> _importedLibraries;
  List<FileState> _exportedLibraries;
  List<FileState> _partFiles;

  Set<FileState> _directReferencedFiles = new Set<FileState>();
  List<FileState> _directReferencedLibraries = <FileState>[];
  Set<FileState> _transitiveFiles;

  /// This flag is set to `true` during the mark phase of garbage collection
  /// and set back to `false` for survived instances.
  bool _gcMarked = false;

  FileState._(this._fsState, this.uri, this.fileUri)
      : uriBytes = UTF8.encode(uri.toString());

  /// The MD5 signature of the file API as a byte array.
  /// It depends on all non-comment tokens outside the block bodies.
  List<int> get apiSignature => _apiSignature;

  /// The content of the file.
  List<int> get content => _content;

  /// The MD5 hash of the [content].
  List<int> get contentHash => _contentHash;

  /// Libraries that this library file directly imports or exports.
  List<FileState> get directReferencedLibraries => _directReferencedLibraries;

  /// Whether the file exists.
  bool get exists => _exists;

  /// The list of the libraries exported by this library.
  List<FileState> get exportedLibraries => _exportedLibraries;

  @override
  int get hashCode => uri.hashCode;

  /// Whether the file has a mixin application.
  bool get hasMixinApplication => _hasMixinApplication;

  /// Whether a unit of the library has a mixin application.
  bool get hasMixinApplicationLibrary {
    return _hasMixinApplication ||
        _partFiles.any((part) => part._hasMixinApplication);
  }

  /// The list of the libraries imported by this library.
  List<FileState> get importedLibraries => _importedLibraries;

  /// The list of files this library file references as parts.
  List<FileState> get partFiles => _partFiles;

  /// Return topologically sorted cycles of dependencies for this library.
  List<LibraryCycle> get topologicalOrder {
    var libraryWalker = new _LibraryWalker();
    libraryWalker.walk(libraryWalker.getNode(this));
    return libraryWalker.topologicallySortedCycles;
  }

  /// Return the set of transitive files - the file itself and all of the
  /// directly or indirectly referenced files.
  Set<FileState> get transitiveFiles {
    if (_transitiveFiles == null) {
      _transitiveFiles = new Set<FileState>.identity();

      void appendReferenced(FileState file) {
        if (_transitiveFiles.add(file)) {
          file._directReferencedFiles.forEach(appendReferenced);
        }
      }

      appendReferenced(this);
    }
    return _transitiveFiles;
  }

  @override
  bool operator ==(Object other) {
    return other is FileState && other.uri == uri;
  }

  /// Read the file content and ensure that all of the file properties are
  /// consistent with the read content, including all its dependencies.
  Future<Null> refresh() async {
    // Read the content.
    try {
      FileSystemEntity entry = _fsState.fileSystem.entityForUri(fileUri);
      _content = await entry.readAsBytes();
      _exists = true;
    } catch (_) {
      _content = new Uint8List(0);
      _exists = false;
    }

    // Compute the content hash.
    _contentHash = md5.convert(_content).bytes;

    // Prepare bytes of the unlinked unit - existing or new.
    List<int> unlinkedBytes;
    {
      String unlinkedKey = hex.encode(_contentHash) + '.unlinked';
      unlinkedBytes = _fsState._byteStore.get(unlinkedKey);
      if (unlinkedBytes == null) {
        var builder = computeUnlinkedUnit(_fsState._salt, _content);
        unlinkedBytes = builder.toBytes();
        _fsState._byteStore.put(unlinkedKey, unlinkedBytes);
      }
    }

    // Read the unlinked unit.
    UnlinkedUnit unlinkedUnit = new UnlinkedUnit(unlinkedBytes);
    _apiSignature = unlinkedUnit.apiSignature;
    _hasMixinApplication = unlinkedUnit.hasMixinApplication;

    // Build the graph.
    _importedLibraries = <FileState>[];
    _exportedLibraries = <FileState>[];
    _partFiles = <FileState>[];
    {
      FileState coreFile = await _getFileForRelativeUri('dart:core');
      // TODO(scheglov) add error handling
      if (coreFile != null) {
        _importedLibraries.add(coreFile);
      }
    }
    for (var import_ in unlinkedUnit.imports) {
      FileState file = await _getFileForRelativeUri(import_.uri);
      if (file != null) {
        _importedLibraries.add(file);
      }
    }
    await _addTargetExtraRequiredLibraries();
    for (var export_ in unlinkedUnit.exports) {
      FileState file = await _getFileForRelativeUri(export_.uri);
      if (file != null) {
        _exportedLibraries.add(file);
      }
    }
    for (var part_ in unlinkedUnit.parts) {
      FileState file = await _getFileForRelativeUri(part_);
      if (file != null) {
        _partFiles.add(file);
      }
    }

    // Compute referenced files.
    var oldDirectReferencedFiles = _directReferencedFiles;
    _directReferencedFiles = new Set<FileState>()
      ..addAll(_importedLibraries)
      ..addAll(_exportedLibraries)
      ..addAll(_partFiles);
    _directReferencedLibraries = (new Set<FileState>()
          ..addAll(_importedLibraries)
          ..addAll(_exportedLibraries))
        .toList();

    // If the set of directly referenced files of this file is changed,
    // then the transitive sets of files that include this file are also
    // changed. Reset these transitive sets.
    if (_directReferencedFiles.length != oldDirectReferencedFiles.length ||
        !_directReferencedFiles.containsAll(oldDirectReferencedFiles)) {
      for (var file in _fsState._uriToFile.values) {
        if (file._transitiveFiles != null &&
            file._transitiveFiles.contains(this)) {
          file._transitiveFiles = null;
        }
      }
    }
  }

  @override
  String toString() {
    if (uri.scheme == 'file') return uri.path;
    return uri.toString();
  }

  /// Fasta unconditionally loads extra libraries based on the target.  In order
  /// to be able to serve them using the file system view, pretend that all of
  /// them were imported into `dart:core`.
  /// TODO(scheglov,sigmund): remove this implicit import, instead make fasta
  /// and IKG aware of extra code that needs to be loaded.
  Future<Null> _addTargetExtraRequiredLibraries() async {
    if (uri.toString() != 'dart:core') return;
    for (String uri in _fsState.target.extraRequiredLibraries) {
      FileState file = await _getFileForRelativeUri(uri);
      // TODO(scheglov) add error handling
      if (file != null) {
        _importedLibraries.add(file);
      }
    }
  }

  /// Return the [FileState] for the given [relativeUri] or `null` if the URI
  /// cannot be parsed, cannot correspond any file, etc.
  Future<FileState> _getFileForRelativeUri(String relativeUri) async {
    if (relativeUri.isEmpty) return null;

    // Resolve the relative URI into absolute.
    // The result is either:
    //   1) The absolute file URI.
    //   2) The absolute non-file URI, e.g. `package:foo/foo.dart`.
    Uri absoluteUri;
    try {
      absoluteUri = resolveRelativeUri(uri, Uri.parse(relativeUri));
    } on FormatException {
      return null;
    }

    return await _fsState.getFile(absoluteUri);
  }
}

/// Information about known file system state.
class FileSystemState {
  final ByteStore _byteStore;
  final FileSystem fileSystem;
  final Target target;
  final UriTranslator uriTranslator;
  final List<int> _salt;
  final NewFileFn _newFileFn;

  _FileSystemView _fileSystemView;

  /// Mapping from import URIs to corresponding [FileState]s. For example, this
  /// may contain an entry for `dart:core`.
  final Map<Uri, FileState> _uriToFile = {};

  /// Mapping from file URIs to corresponding [FileState]s. This map should only
  /// contain `file:*` URIs as keys.
  final Map<Uri, FileState> _fileUriToFile = {};

  /// The set of absolute URIs with the `dart` scheme that should be skipped.
  /// We do this when we use SDK outline instead of compiling SDK sources.
  final Set<Uri> skipSdkLibraries = new Set<Uri>();

  FileSystemState(this._byteStore, this.fileSystem, this.target,
      this.uriTranslator, this._salt, this._newFileFn);

  /// Return the [FileSystem] that is backed by this [FileSystemState].  The
  /// files in this [FileSystem] always have the same content as the
  /// corresponding [FileState]s, thus avoiding race conditions when a file
  /// is updated on the actual file system.
  FileSystem get fileSystemView {
    return _fileSystemView ??= new _FileSystemView(this);
  }

  /// The `file:` URI of all files currently tracked by this instance.
  Iterable<Uri> get fileUris => _fileUriToFile.keys;

  /// Perform mark and sweep garbage collection of [FileState]s.
  /// Return [FileState]s that became garbage.
  List<FileState> gc(Uri entryPoint) {
    void mark(FileState file) {
      if (!file._gcMarked) {
        file._gcMarked = true;
        file._directReferencedFiles.forEach(mark);
      }
    }

    var file = _uriToFile[entryPoint];
    if (file == null) return const [];

    mark(file);

    var filesToRemove = <FileState>[];
    var urisToRemove = new Set<Uri>();
    var fileUrisToRemove = new Set<Uri>();
    for (var file in _uriToFile.values) {
      if (file._gcMarked) {
        file._gcMarked = false;
      } else {
        filesToRemove.add(file);
        urisToRemove.add(file.uri);
        fileUrisToRemove.add(file.fileUri);
      }
    }

    urisToRemove.forEach(_uriToFile.remove);
    fileUrisToRemove.forEach(_fileUriToFile.remove);
    return filesToRemove;
  }

  /// Return the [FileState] for the given [absoluteUri], or `null` if the
  /// [absoluteUri] cannot be resolved into a file URI.
  ///
  /// The returned file has the last known state since it was last refreshed.
  Future<FileState> getFile(Uri absoluteUri) async {
    // We don't need to process SDK libraries if we have SDK outline.
    if (skipSdkLibraries.contains(absoluteUri)) {
      return null;
    }

    // Resolve the absolute URI into the absolute file URI.
    Uri fileUri;
    if (absoluteUri.isScheme('file')) {
      fileUri = absoluteUri;
    } else {
      fileUri = uriTranslator.translate(absoluteUri);
      if (fileUri == null) return null;
    }

    FileState file = _uriToFile[absoluteUri];
    if (file == null) {
      file = new FileState._(this, absoluteUri, fileUri);
      _uriToFile[absoluteUri] = file;
      _fileUriToFile[fileUri] = file;

      // Notify the function about a new file.
      if (_newFileFn != null) {
        await _newFileFn(fileUri);
      }

      // Build the sub-graph of the file.
      await file.refresh();
    }
    return file;
  }

  /// Return the [FileState] for the given [fileUri], or `null` if the
  /// [fileUri] does not yet correspond to any referenced [FileState].
  FileState getFileByFileUri(Uri fileUri) => _fileUriToFile[fileUri];
}

/// List of libraries that reference each other, so form a cycle.
class LibraryCycle {
  final List<FileState> libraries = <FileState>[];

  /// The cycles this cycle directly depends on.
  final Set<LibraryCycle> directDependencies = new Set<LibraryCycle>();

  /// The cycles that directly import or export this cycle.
  final List<LibraryCycle> directUsers = <LibraryCycle>[];

  bool get _isForVm {
    return libraries.any((l) => l.uri.toString().endsWith('dart:_vmservice'));
  }

  @override
  String toString() {
    if (_isForVm) {
      return '[core + vm]';
    }
    return '[' + libraries.join(', ') + ']';
  }
}

/// [FileSystemState] based implementation of [FileSystem].
/// It provides a consistent view on the known file system state.
class _FileSystemView implements FileSystem {
  final FileSystemState fsState;

  _FileSystemView(this.fsState);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    FileState file = fsState._fileUriToFile[uri];
    return new _FileSystemViewEntry(uri, file);
  }
}

/// [FileSystemState] based implementation of [FileSystemEntity].
class _FileSystemViewEntry implements FileSystemEntity {
  @override
  final Uri uri;

  final FileState file;

  _FileSystemViewEntry(this.uri, this.file);

  @override
  Future<bool> exists() async => _shouldNotBeQueried();

  @override
  Future<List<int>> readAsBytes() async {
    if (file == null) {
      throw new FileSystemException(uri, 'File $uri does not exist.');
    }
    return file.content;
  }

  @override
  Future<String> readAsString() async => _shouldNotBeQueried();

  /// [_FileSystemViewEntry] is used by the incremental kernel generator to
  /// provide Fasta with a consistent, race condition free view of the files
  /// constituting the project.  It should only need to be used for reading
  /// file contents.
  dynamic _shouldNotBeQueried() {
    throw new StateError('The method should not be invoked.');
  }
}

/// Node in [_LibraryWalker].
class _LibraryNode extends graph.Node<_LibraryNode> {
  final _LibraryWalker walker;
  final FileState file;

  @override
  bool isEvaluated = false;

  _LibraryNode(this.walker, this.file);

  @override
  List<_LibraryNode> computeDependencies() {
    return file.directReferencedLibraries.map(walker.getNode).toList();
  }
}

/// Helper that organizes dependencies of a library into topologically
/// sorted [LibraryCycle]s.
class _LibraryWalker extends graph.DependencyWalker<_LibraryNode> {
  final nodesOfFiles = <FileState, _LibraryNode>{};
  final fileToCycleMap = <FileState, LibraryCycle>{};
  final topologicallySortedCycles = <LibraryCycle>[];

  @override
  void evaluate(_LibraryNode v) {
    evaluateScc([v]);
  }

  @override
  void evaluateScc(List<_LibraryNode> scc) {
    var cycle = new LibraryCycle();

    // Compute direct dependencies.
    for (var node in scc) {
      var file = node.file;
      for (var importedLibrary in file.importedLibraries) {
        var importedCycle = fileToCycleMap[importedLibrary];
        if (importedCycle != null) {
          cycle.directDependencies.add(importedCycle);
        }
      }
      for (var exportedLibrary in file.exportedLibraries) {
        var exportedCycle = fileToCycleMap[exportedLibrary];
        if (exportedCycle != null) {
          cycle.directDependencies.add(exportedCycle);
        }
      }
    }

    // Register this cycle as a direct user of the direct dependencies.
    for (var directDependency in cycle.directDependencies) {
      directDependency.directUsers.add(cycle);
    }

    // Fill the cycle with libraries.
    for (var node in scc) {
      node.isEvaluated = true;
      cycle.libraries.add(node.file);
      fileToCycleMap[node.file] = cycle;
    }

    topologicallySortedCycles.add(cycle);
  }

  _LibraryNode getNode(FileState file) {
    return nodesOfFiles.putIfAbsent(file, () => new _LibraryNode(this, file));
  }
}
