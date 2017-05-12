// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:front_end/file_system.dart';
import 'package:front_end/src/dependency_walker.dart' as graph;
import 'package:front_end/src/fasta/parser/top_level_parser.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/fasta/source/directive_listener.dart';
import 'package:front_end/src/fasta/translate_uri.dart';

/// Information about a file being compiled, explicitly or implicitly.
///
/// It provides a consistent view on its properties.
///
/// The properties are not guaranteed to represent the most recent state
/// of the file system. To update the file to the most recent state, [refresh]
/// should be called.
class FileState {
  final FileSystemState _fsState;

  /// The resolved URI of the file in the file system.
  final Uri fileUri;

  bool _exists;
  List<int> _content;

  List<FileState> _importedLibraries;
  List<FileState> _exportedLibraries;
  List<FileState> _partFiles;

  List<FileState> _directReferencedLibraries = <FileState>[];

  FileState._(this._fsState, this.fileUri);

  /// The content of the file.
  List<int> get content => _content;

  /// Libraries that this library file directly imports or exports.
  List<FileState> get directReferencedLibraries => _directReferencedLibraries;

  /// Whether the file exists.
  bool get exists => _exists;

  /// The list of the libraries exported by this library.
  List<FileState> get exportedLibraries => _exportedLibraries;

  @override
  int get hashCode => fileUri.hashCode;

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

  @override
  bool operator ==(Object other) {
    return other is FileState && other.fileUri == fileUri;
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

    // Parse directives.
    ScannerResult scannerResults = _scan();
    var listener = new DirectiveListener();
    new TopLevelParser(listener).parseUnit(scannerResults.tokens);

    // Build the graph.
    _importedLibraries = <FileState>[];
    _exportedLibraries = <FileState>[];
    _partFiles = <FileState>[];
    await _addFileForRelativeUri(_importedLibraries, 'dart:core');
    for (String uri in listener.imports) {
      await _addFileForRelativeUri(_importedLibraries, uri);
    }
    for (String uri in listener.exports) {
      await _addFileForRelativeUri(_exportedLibraries, uri);
    }
    for (String uri in listener.parts) {
      await _addFileForRelativeUri(_partFiles, uri);
    }

    // Compute referenced libraries.
    _directReferencedLibraries = (new Set<FileState>()
          ..addAll(_importedLibraries)
          ..addAll(_exportedLibraries))
        .toList();
  }

  @override
  String toString() {
    if (fileUri.scheme == 'file') return fileUri.path;
    return fileUri.toString();
  }

  /// Add the [FileState] for the given [relativeUri] to the [files].
  /// Do nothing if the URI cannot be parsed, cannot correspond any file, etc.
  Future<Null> _addFileForRelativeUri(
      List<FileState> files, String relativeUri) async {
    if (relativeUri.isEmpty) return;

    // Resolve the relative URI into absolute.
    // The result is either:
    //   1) The absolute file URI.
    //   2) The absolute non-file URI, e.g. `package:foo/foo.dart`.
    Uri absoluteUri;
    try {
      absoluteUri = fileUri.resolve(relativeUri);
    } on FormatException {
      return;
    }

    // Resolve the absolute URI into the absolute file URI.
    Uri resolvedUri;
    if (absoluteUri.isScheme('file')) {
      resolvedUri = absoluteUri;
    } else {
      resolvedUri = _fsState.uriTranslator.translate(absoluteUri);
      if (resolvedUri == null) return;
    }

    FileState file = await _fsState.getFile(resolvedUri);
    files.add(file);
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

  /// Mapping from file URIs to corresponding [FileState]s.
  final Map<Uri, FileState> _fileUriToFile = {};

  FileSystemState(this.fileSystem, this.uriTranslator);

  /// Return the [FileSystem] that is backed by this [FileSystemState].  The
  /// files in this [FileSystem] always have the same content as the
  /// corresponding [FileState]s, thus avoiding race conditions when a file
  /// is updated on the actual file system.
  FileSystem get fileSystemView {
    return _fileSystemView ??= new _FileSystemView(this);
  }

  /// Return the [FileState] for the given resolved file [fileUri].
  /// The returned file has the last known state since it was last refreshed.
  Future<FileState> getFile(Uri fileUri) async {
    FileState file = _fileUriToFile[fileUri];
    if (file == null) {
      file = new FileState._(this, fileUri);
      _fileUriToFile[fileUri] = file;

      // Build the sub-graph of the file.
      await file.refresh();
    }
    return file;
  }
}

/// List of libraries that reference each other, so form a cycle.
class LibraryCycle {
  final List<FileState> libraries = <FileState>[];

  @override
  String toString() => '[' + libraries.join(', ') + ']';
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
