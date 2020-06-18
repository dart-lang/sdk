// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

String _encodeDevFSDisabledError(Message message) =>
    encodeRpcError(message, kFeatureDisabled,
        details: 'DevFS is not supported by this Dart implementation');

String _encodeFileSystemAlreadyExistsError(Message message, String fsName) =>
    encodeRpcError(message, kFileSystemAlreadyExists,
        details: "${message.method}: file system '${fsName}' already exists");

String _encodeFileSystemDoesNotExistError(Message message, String fsName) =>
    encodeRpcError(message, kFileSystemDoesNotExist,
        details: "${message.method}: file system '${fsName}' does not exist");

class _FileSystem {
  _FileSystem(this.name, this.uri);

  final String name;
  final Uri uri;

  Uri? resolvePath(String path) {
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.isEmpty) {
      return null;
    }
    Uri pathUri;
    try {
      pathUri = Uri.file(path);
      // ignore: unused_catch_clause
    } on FormatException catch (_) {
      return null;
    }

    return resolve(pathUri);
  }

  Uri? resolve(Uri pathUri) {
    try {
      // Make sure that this pathUri can be converted to a file path.
      pathUri.toFilePath();
      // ignore: unused_catch_clause
    } on UnsupportedError catch (_) {
      return null;
    }

    final resolvedUri = uri.resolveUri(pathUri);
    if (!resolvedUri.toString().startsWith(uri.toString())) {
      // Resolved uri must be within the filesystem's base uri.
      return null;
    }
    return resolvedUri;
  }

  Map<String, String> toMap() => {
        'type': 'FileSystem',
        'name': name,
        'uri': uri.toString(),
      };
}

class DevFS {
  DevFS();

  final _fsMap = <String, _FileSystem>{};

  final _rpcNames = <String>{
    '_listDevFS',
    '_createDevFS',
    '_deleteDevFS',
    '_readDevFSFile',
    '_writeDevFSFile',
    '_writeDevFSFiles',
    '_listDevFSFiles',
  };

  void cleanup() {
    final deleteDir = VMServiceEmbedderHooks.deleteDir;
    if (deleteDir == null) {
      return;
    }
    final deletions = <Future>[
      for (final fs in _fsMap.values) deleteDir(fs.uri),
    ];
    Future.wait(deletions);
    _fsMap.clear();
  }

  bool shouldHandleMessage(Message message) =>
      _rpcNames.contains(message.method);

  Future<String> handleMessage(Message message) async {
    switch (message.method!) {
      case '_listDevFS':
        return _listDevFS(message);
      case '_createDevFS':
        return _createDevFS(message);
      case '_deleteDevFS':
        return _deleteDevFS(message);
      case '_readDevFSFile':
        return _readDevFSFile(message);
      case '_writeDevFSFile':
        return _writeDevFSFile(message);
      case '_writeDevFSFiles':
        return _writeDevFSFiles(message);
      case '_listDevFSFiles':
        return _listDevFSFiles(message);
      default:
        return encodeRpcError(message, kInternalError,
            details: 'Unexpected rpc ${message.method}');
    }
  }

  Future<String> handlePutStream(
      Object? fsName, Object? path, Uri? fsUri, Stream<List<int>> bytes) async {
    // A dummy Message for error message construction.
    final message = Message.forMethod('_writeDevFSFile');
    final writeStreamFile = VMServiceEmbedderHooks.writeStreamFile;
    if (writeStreamFile == null) {
      return _encodeDevFSDisabledError(message);
    }
    if (fsName == null) {
      return encodeMissingParamError(message, 'fsName');
    }
    if (fsName is! String) {
      return encodeInvalidParamError(message, 'fsName');
    }
    var fs = _fsMap[fsName];
    if (fs == null) {
      return _encodeFileSystemDoesNotExistError(message, fsName);
    }
    Uri? uri = fsUri;
    if (uri == null) {
      if (path == null) {
        return encodeMissingParamError(message, 'path');
      }
      if (path is! String) {
        return encodeInvalidParamError(message, 'path');
      }
      uri = fs.resolvePath(path);
      if (uri == null) {
        return encodeInvalidParamError(message, 'path');
      }
    } else {
      uri = fs.resolve(uri);
      if (uri == null) {
        return encodeInvalidParamError(message, 'uri');
      }
    }
    await writeStreamFile(uri, bytes);
    return encodeSuccess(message);
  }

  Future<String> _listDevFS(Message message) async {
    final result = <String, dynamic>{};
    result['type'] = 'FileSystemList';
    result['fsNames'] = _fsMap.keys.toList();
    return encodeResult(message, result);
  }

  Future<String> _createDevFS(Message message) async {
    final createTempDir = VMServiceEmbedderHooks.createTempDir;
    if (createTempDir == null) {
      return _encodeDevFSDisabledError(message);
    }
    final fsName = message.params['fsName'];
    if (fsName == null) {
      return encodeMissingParamError(message, 'fsName');
    }
    if (fsName is! String) {
      return encodeInvalidParamError(message, 'fsName');
    }
    _FileSystem? fs = _fsMap[fsName];
    if (fs != null) {
      return _encodeFileSystemAlreadyExistsError(message, fsName);
    }
    final tempDir = await createTempDir(fsName);
    fs = _FileSystem(fsName, tempDir);
    _fsMap[fsName] = fs;
    return encodeResult(message, fs.toMap());
  }

  Future<String> _deleteDevFS(Message message) async {
    final deleteDir = VMServiceEmbedderHooks.deleteDir;
    if (deleteDir == null) {
      return _encodeDevFSDisabledError(message);
    }
    final fsName = message.params['fsName'];
    if (fsName == null) {
      return encodeMissingParamError(message, 'fsName');
    }
    if (fsName is! String) {
      return encodeInvalidParamError(message, 'fsName');
    }
    final fs = _fsMap.remove(fsName);
    if (fs == null) {
      return _encodeFileSystemDoesNotExistError(message, fsName);
    }
    await deleteDir(fs.uri);
    return encodeSuccess(message);
  }

  Future<String> _readDevFSFile(Message message) async {
    final readFile = VMServiceEmbedderHooks.readFile;
    if (readFile == null) {
      return _encodeDevFSDisabledError(message);
    }
    final fsName = message.params['fsName'];
    if (fsName == null) {
      return encodeMissingParamError(message, 'fsName');
    }
    if (fsName is! String) {
      return encodeInvalidParamError(message, 'fsName');
    }
    final fs = _fsMap[fsName];
    if (fs == null) {
      return _encodeFileSystemDoesNotExistError(message, fsName);
    }
    Uri? uri;
    if (message.params['uri'] != null) {
      try {
        final uriParam = message.params['uri'];
        if (uriParam is! String) {
          return encodeInvalidParamError(message, 'uri');
        }
        final parsedUri = Uri.parse(uriParam);
        uri = fs.resolve(parsedUri);
        if (uri == null) {
          return encodeInvalidParamError(message, 'uri');
        }
      } catch (e) {
        return encodeInvalidParamError(message, 'uri');
      }
    } else {
      final path = message.params['path'];
      if (path == null) {
        return encodeMissingParamError(message, 'path');
      }
      if (path is! String) {
        return encodeInvalidParamError(message, 'path');
      }
      uri = fs.resolvePath(path);
      if (uri == null) {
        return encodeInvalidParamError(message, 'path');
      }
    }
    try {
      final bytes = await readFile(uri);
      final result = {'type': 'FSFile', 'fileContents': base64.encode(bytes)};
      return encodeResult(message, result);
    } catch (e) {
      return encodeRpcError(message, kFileDoesNotExist,
          details: '_readDevFSFile: $e');
    }
  }

  Future<String> _writeDevFSFile(Message message) async {
    final writeFile = VMServiceEmbedderHooks.writeFile;
    if (writeFile == null) {
      return _encodeDevFSDisabledError(message);
    }
    final fsName = message.params['fsName'];
    if (fsName == null) {
      return encodeMissingParamError(message, 'fsName');
    }
    if (fsName is! String) {
      return encodeInvalidParamError(message, 'fsName');
    }
    final fs = _fsMap[fsName];
    if (fs == null) {
      return _encodeFileSystemDoesNotExistError(message, fsName);
    }
    Uri? uri;
    if (message.params['uri'] != null) {
      try {
        final uriParam = message.params['uri'];
        if (uriParam is! String) {
          return encodeInvalidParamError(message, 'uri');
        }
        final parsedUri = Uri.parse(uriParam);
        uri = fs.resolve(parsedUri);
        if (uri == null) {
          return encodeInvalidParamError(message, 'uri');
        }
      } catch (e) {
        return encodeInvalidParamError(message, 'uri');
      }
    } else {
      final path = message.params['path'];
      if (path == null) {
        return encodeMissingParamError(message, 'path');
      }
      if (path is! String) {
        return encodeInvalidParamError(message, 'path');
      }
      uri = fs.resolvePath(path);
      if (uri == null) {
        return encodeInvalidParamError(message, 'path');
      }
    }
    final fileContents = message.params['fileContents'];
    if (fileContents == null) {
      return encodeMissingParamError(message, 'fileContents');
    }
    if (fileContents is! String) {
      return encodeInvalidParamError(message, 'fileContents');
    }
    final decodedFileContents = base64.decode(fileContents);

    await writeFile(uri, decodedFileContents);
    return encodeSuccess(message);
  }

  Future<String> _writeDevFSFiles(Message message) async {
    final writeFile = VMServiceEmbedderHooks.writeFile;
    if (writeFile == null) {
      return _encodeDevFSDisabledError(message);
    }
    final fsName = message.params['fsName'];
    if (fsName == null) {
      return encodeMissingParamError(message, 'fsName');
    }
    if (fsName is! String) {
      return encodeInvalidParamError(message, 'fsName');
    }
    final fs = _fsMap[fsName];
    if (fs == null) {
      return _encodeFileSystemDoesNotExistError(message, fsName);
    }
    final files = message.params['files'];
    if (files == null) {
      return encodeMissingParamError(message, 'files');
    }
    if (files is! List) {
      return encodeInvalidParamError(message, 'files');
    }
    final uris = <Uri>[];
    for (int i = 0; i < files.length; i++) {
      final fileInfo = files[i];
      if (fileInfo is! List ||
          fileInfo.length != 2 ||
          fileInfo[0] is! String ||
          fileInfo[1] is! String) {
        return encodeRpcError(message, kInvalidParams,
            details: "${message.method}: invalid 'files' parameter "
                "at index ${i}: ${fileInfo}");
      }
      final uri = fs.resolvePath(fileInfo[0]);
      if (uri == null) {
        return encodeRpcError(message, kInvalidParams,
            details: "${message.method}: invalid 'files' parameter "
                "at index ${i}: ${fileInfo}");
      }
      uris.add(uri);
    }
    final pendingWrites = <Future>[];
    for (int i = 0; i < uris.length; i++) {
      final decodedFileContents = base64.decode(files[i][1]);
      pendingWrites.add(writeFile(uris[i], decodedFileContents));
    }
    await Future.wait(pendingWrites);
    return encodeSuccess(message);
  }

  Future<String> _listDevFSFiles(Message message) async {
    final listFiles = VMServiceEmbedderHooks.listFiles;
    if (listFiles == null) {
      return _encodeDevFSDisabledError(message);
    }
    final fsName = message.params['fsName'];
    if (fsName == null) {
      return encodeMissingParamError(message, 'fsName');
    }
    if (fsName is! String) {
      return encodeInvalidParamError(message, 'fsName');
    }
    final fs = _fsMap[fsName];
    if (fs == null) {
      return _encodeFileSystemDoesNotExistError(message, fsName);
    }
    final fileList = await listFiles(fs.uri);
    // Remove any url-encoding in the filenames.
    for (int i = 0; i < fileList.length; i++) {
      fileList[i]['name'] = Uri.decodeFull(fileList[i]['name']);
    }
    final result = <String, dynamic>{'type': 'FSFileList', 'files': fileList};
    return encodeResult(message, result);
  }
}
