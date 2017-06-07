// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/src/base/resolve_relative_uri.dart';
import 'package:front_end/src/dependency_walker.dart' as graph;
import 'package:front_end/src/fasta/parser/dart_vm_native.dart';
import 'package:front_end/src/fasta/parser/top_level_parser.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/fasta/source/directive_listener.dart';
import 'package:front_end/src/fasta/translate_uri.dart';
import 'package:kernel/target/vm.dart';

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

  /// The resolved URI of the file in the file system.
  final Uri fileUri;

  bool _exists;
  List<int> _content;
  List<int> _contentHash;

  List<NamespaceExport> _exports;
  List<FileState> _importedLibraries;
  List<FileState> _exportedLibraries;
  List<FileState> _partFiles;

  Set<FileState> _directReferencedFiles = new Set<FileState>();
  List<FileState> _directReferencedLibraries = <FileState>[];

  FileState._(this._fsState, this.uri, this.fileUri);

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

  /// The list of the exported files with combinators.
  List<NamespaceExport> get exports => _exports;

  @override
  int get hashCode => uri.hashCode;

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
    // TODO(scheglov) add caching.
    var transitiveFiles = new Set<FileState>();

    void appendReferenced(FileState file) {
      if (transitiveFiles.add(file)) {
        file._directReferencedFiles.forEach(appendReferenced);
      }
    }

    appendReferenced(this);
    return transitiveFiles;
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

    // Parse directives.
    ScannerResult scannerResults = _scan();
    var listener = new _DirectiveListenerWithNative();
    new TopLevelParser(listener).parseUnit(scannerResults.tokens);

    // Build the graph.
    _importedLibraries = <FileState>[];
    _exportedLibraries = <FileState>[];
    _partFiles = <FileState>[];
    _exports = <NamespaceExport>[];
    {
      FileState coreFile = await _getFileForRelativeUri('dart:core');
      // TODO(scheglov) add error handling
      if (coreFile != null) {
        _importedLibraries.add(coreFile);
      }
    }
    for (NamespaceDirective import_ in listener.imports) {
      FileState file = await _getFileForRelativeUri(import_.uri);
      if (file != null) {
        _importedLibraries.add(file);
      }
    }
    await _addVmTargetImportsForCore();
    for (NamespaceDirective export_ in listener.exports) {
      FileState file = await _getFileForRelativeUri(export_.uri);
      if (file != null) {
        _exportedLibraries.add(file);
        _exports.add(new NamespaceExport(file, export_.combinators));
      }
    }
    for (String uri in listener.parts) {
      FileState file = await _getFileForRelativeUri(uri);
      if (file != null) {
        _partFiles.add(file);
      }
    }

    // Compute referenced files.
    _directReferencedFiles = new Set<FileState>()
      ..addAll(_importedLibraries)
      ..addAll(_exportedLibraries)
      ..addAll(_partFiles);
    _directReferencedLibraries = (new Set<FileState>()
          ..addAll(_importedLibraries)
          ..addAll(_exportedLibraries))
        .toList();
  }

  @override
  String toString() {
    if (uri.scheme == 'file') return uri.path;
    return uri.toString();
  }

  /// Fasta unconditionally loads all VM libraries.  In order to be able to
  /// serve them using the file system view, pretend that all of them were
  /// imported into `dart:core`.
  /// TODO(scheglov) Ask VM people whether all these libraries are required.
  Future<Null> _addVmTargetImportsForCore() async {
    if (uri.toString() != 'dart:core') return;
    for (String uri in new VmTarget(null).extraRequiredLibraries) {
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

  /// Scan the content of the file.
  ScannerResult _scan() {
    var zeroTerminatedBytes = new Uint8List(_content.length + 1);
    zeroTerminatedBytes.setRange(0, _content.length, _content);
    return scan(zeroTerminatedBytes);
  }
}

/// Information about known file system state.
class FileSystemState {
  final FileSystem fileSystem;
  final TranslateUri uriTranslator;

  _FileSystemView _fileSystemView;

  /// Mapping from import URIs to corresponding [FileState]s. For example, this
  /// may contain an entry for `dart:core`.
  final Map<Uri, FileState> _uriToFile = {};

  /// Mapping from file URIs to corresponding [FileState]s. This map should only
  /// contain `file:*` URIs as keys.
  final Map<Uri, FileState> _fileUriToFile = {};

  FileSystemState(this.fileSystem, this.uriTranslator);

  /// Return the [FileSystem] that is backed by this [FileSystemState].  The
  /// files in this [FileSystem] always have the same content as the
  /// corresponding [FileState]s, thus avoiding race conditions when a file
  /// is updated on the actual file system.
  FileSystem get fileSystemView {
    return _fileSystemView ??= new _FileSystemView(this);
  }

  /// The `file:` URI of all files currently tracked by this instance.
  Iterable<Uri> get fileUris => _fileUriToFile.keys;

  /// Return the [FileState] for the given [absoluteUri], or `null` if the
  /// [absoluteUri] cannot be resolved into a file URI.
  ///
  /// The returned file has the last known state since it was last refreshed.
  Future<FileState> getFile(Uri absoluteUri) async {
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

/// Information about a single `export` directive.
class NamespaceExport {
  final FileState library;
  final List<NamespaceCombinator> combinators;

  NamespaceExport(this.library, this.combinators);

  /// Return `true` if the [name] satisfies the sequence of the [combinators].
  bool isExposed(String name) {
    for (NamespaceCombinator combinator in combinators) {
      if (combinator.isShow) {
        if (!combinator.names.contains(name)) {
          return false;
        }
      } else {
        if (combinator.names.contains(name)) {
          return false;
        }
      }
    }
    return true;
  }
}

/// [DirectiveListener] that skips native clauses.
class _DirectiveListenerWithNative extends DirectiveListener {
  @override
  Token handleNativeClause(Token token) => skipNativeClause(token);
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
  Future<DateTime> lastModified() async => _shouldNotBeQueried();

  @override
  Future<List<int>> readAsBytes() async {
    if (file == null) {
      throw new FileSystemException(uri, 'File $uri does not exist.');
    }
    return file.content;
  }

  @override
  Future<String> readAsString() async => _shouldNotBeQueried();

  /// _FileSystemViewEntry is used by the incremental kernel generator to
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
  final topologicallySortedCycles = <LibraryCycle>[];

  @override
  void evaluate(_LibraryNode v) {
    evaluateScc([v]);
  }

  @override
  void evaluateScc(List<_LibraryNode> scc) {
    var cycle = new LibraryCycle();
    for (var node in scc) {
      node.isEvaluated = true;
      cycle.libraries.add(node.file);
    }
    topologicallySortedCycles.add(cycle);
  }

  _LibraryNode getNode(FileState file) {
    return nodesOfFiles.putIfAbsent(file, () => new _LibraryNode(this, file));
  }
}
