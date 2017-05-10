// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:front_end/file_system.dart';
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

  List<FileState> _importedFiles;
  List<FileState> _exportedFiles;
  List<FileState> _partFiles;

  Set<FileState> _directReferencedFiles = new Set<FileState>();

  FileState._(this._fsState, this.fileUri);

  /// The content of the file.
  List<int> get content => _content;

  /// Whether the file exists.
  bool get exists => _exists;

  @override
  int get hashCode => fileUri.hashCode;

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
    _importedFiles = <FileState>[];
    _exportedFiles = <FileState>[];
    _partFiles = <FileState>[];
    await _addFileForRelativeUri(_importedFiles, 'dart:core');
    for (String uri in listener.imports) {
      await _addFileForRelativeUri(_importedFiles, uri);
    }
    for (String uri in listener.exports) {
      await _addFileForRelativeUri(_exportedFiles, uri);
    }
    for (String uri in listener.parts) {
      await _addFileForRelativeUri(_partFiles, uri);
    }

    // Compute referenced files.
    _directReferencedFiles = new Set<FileState>()
      ..addAll(_importedFiles)
      ..addAll(_exportedFiles)
      ..addAll(_partFiles);
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
