// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

String _encodeDevFSDisabledError(Message message) {
  return encodeRpcError(message, kFeatureDisabled,
      details: "DevFS is not supported by this Dart implementation");
}

String _encodeFileSystemAlreadyExistsError(Message message, String fsName) {
  return encodeRpcError(message, kFileSystemAlreadyExists,
      details: "${message.method}: file system '${fsName}' already exists");
}

String _encodeFileSystemDoesNotExistError(Message message, String fsName) {
  return encodeRpcError(message, kFileSystemDoesNotExist,
      details: "${message.method}: file system '${fsName}' does not exist");
}

class _FileSystem {
  _FileSystem(this.name, this.uri);

  final String name;
  final Uri uri;

  Uri resolvePath(String path) {
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.isEmpty) {
      return null;
    }
    Uri pathUri;
    try {
      pathUri = new Uri.file(path);
    } on FormatException catch (e) {
      return null;
    }

    return resolve(pathUri);
  }

  Uri resolve(Uri pathUri) {
    try {
      // Make sure that this pathUri can be converted to a file path.
      pathUri.toFilePath();
    } on UnsupportedError catch (e) {
      return null;
    }

    Uri resolvedUri = uri.resolveUri(pathUri);
    if (!resolvedUri.toString().startsWith(uri.toString())) {
      // Resolved uri must be within the filesystem's base uri.
      return null;
    }
    return resolvedUri;
  }

  Map toMap() {
    return {
      'type': 'FileSystem',
      'name': name,
      'uri': uri.toString(),
    };
  }
}

class DevFS {
  DevFS();

  Map<String, _FileSystem> _fsMap = {};

  final Set _rpcNames = new Set.from([
    '_listDevFS',
    '_createDevFS',
    '_deleteDevFS',
    '_readDevFSFile',
    '_writeDevFSFile',
    '_writeDevFSFiles',
    '_listDevFSFiles',
  ]);

  void cleanup() {
    var deleteDir = VMServiceEmbedderHooks.deleteDir;
    if (deleteDir == null) {
      return;
    }
    var deletions = <Future>[];
    for (var fs in _fsMap.values) {
      deletions.add(deleteDir(fs.uri));
    }
    Future.wait(deletions);
    _fsMap.clear();
  }

  bool shouldHandleMessage(Message message) {
    return _rpcNames.contains(message.method);
  }

  Future<String> handleMessage(Message message) async {
    switch (message.method) {
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
      Object fsName, Object path, Uri fsUri, Stream<List<int>> bytes) async {
    // A dummy Message for error message construction.
    Message message = new Message.forMethod('_writeDevFSFile');
    var writeStreamFile = VMServiceEmbedderHooks.writeStreamFile;
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
    Uri uri = fsUri;
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
    var result = {};
    result['type'] = 'FileSystemList';
    result['fsNames'] = _fsMap.keys.toList();
    return encodeResult(message, result);
  }

  Future<String> _createDevFS(Message message) async {
    var createTempDir = VMServiceEmbedderHooks.createTempDir;
    if (createTempDir == null) {
      return _encodeDevFSDisabledError(message);
    }
    var fsName = message.params['fsName'];
    if (fsName == null) {
      return encodeMissingParamError(message, 'fsName');
    }
    if (fsName is! String) {
      return encodeInvalidParamError(message, 'fsName');
    }
    var fs = _fsMap[fsName];
    if (fs != null) {
      return _encodeFileSystemAlreadyExistsError(message, fsName);
    }
    var tempDir = await createTempDir(fsName);
    fs = new _FileSystem(fsName, tempDir);
    _fsMap[fsName] = fs;
    return encodeResult(message, fs.toMap());
  }

  Future<String> _deleteDevFS(Message message) async {
    var deleteDir = VMServiceEmbedderHooks.deleteDir;
    if (deleteDir == null) {
      return _encodeDevFSDisabledError(message);
    }
    var fsName = message.params['fsName'];
    if (fsName == null) {
      return encodeMissingParamError(message, 'fsName');
    }
    if (fsName is! String) {
      return encodeInvalidParamError(message, 'fsName');
    }
    var fs = _fsMap.remove(fsName);
    if (fs == null) {
      return _encodeFileSystemDoesNotExistError(message, fsName);
    }
    await deleteDir(fs.uri);
    return encodeSuccess(message);
  }

  Future<String> _readDevFSFile(Message message) async {
    var readFile = VMServiceEmbedderHooks.readFile;
    if (readFile == null) {
      return _encodeDevFSDisabledError(message);
    }
    var fsName = message.params['fsName'];
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
    Uri uri;
    if (message.params['uri'] != null) {
      try {
        var uriParam = message.params['uri'];
        if (uriParam is! String) {
          return encodeInvalidParamError(message, 'uri');
        }
        Uri parsedUri = Uri.parse(uriParam);
        uri = fs.resolve(parsedUri);
        if (uri == null) {
          return encodeInvalidParamError(message, 'uri');
        }
      } catch (e) {
        return encodeInvalidParamError(message, 'uri');
      }
    } else {
      var path = message.params['path'];
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
      List<int> bytes = await readFile(uri);
      var result = {'type': 'FSFile', 'fileContents': base64.encode(bytes)};
      return encodeResult(message, result);
    } catch (e) {
      return encodeRpcError(message, kFileDoesNotExist,
          details: "_readDevFSFile: $e");
    }
  }

  Future<String> _writeDevFSFile(Message message) async {
    var writeFile = VMServiceEmbedderHooks.writeFile;
    if (writeFile == null) {
      return _encodeDevFSDisabledError(message);
    }
    var fsName = message.params['fsName'];
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
    Uri uri;
    if (message.params['uri'] != null) {
      try {
        var uriParam = message.params['uri'];
        if (uriParam is! String) {
          return encodeInvalidParamError(message, 'uri');
        }
        Uri parsedUri = Uri.parse(uriParam);
        uri = fs.resolve(parsedUri);
        if (uri == null) {
          return encodeInvalidParamError(message, 'uri');
        }
      } catch (e) {
        return encodeInvalidParamError(message, 'uri');
      }
    } else {
      var path = message.params['path'];
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
    var fileContents = message.params['fileContents'];
    if (fileContents == null) {
      return encodeMissingParamError(message, 'fileContents');
    }
    if (fileContents is! String) {
      return encodeInvalidParamError(message, 'fileContents');
    }
    List<int> decodedFileContents = base64.decode(fileContents);

    await writeFile(uri, decodedFileContents);
    return encodeSuccess(message);
  }

  Future<String> _writeDevFSFiles(Message message) async {
    var writeFile = VMServiceEmbedderHooks.writeFile;
    if (writeFile == null) {
      return _encodeDevFSDisabledError(message);
    }
    var fsName = message.params['fsName'];
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
    var files = message.params['files'];
    if (files == null) {
      return encodeMissingParamError(message, 'files');
    }
    if (files is! List) {
      return encodeInvalidParamError(message, 'files');
    }
    var uris = [];
    for (int i = 0; i < files.length; i++) {
      var fileInfo = files[i];
      if (fileInfo is! List ||
          fileInfo.length != 2 ||
          fileInfo[0] is! String ||
          fileInfo[1] is! String) {
        return encodeRpcError(message, kInvalidParams,
            details: "${message.method}: invalid 'files' parameter "
                "at index ${i}: ${fileInfo}");
      }
      var uri = fs.resolvePath(fileInfo[0]);
      if (uri == null) {
        return encodeRpcError(message, kInvalidParams,
            details: "${message.method}: invalid 'files' parameter "
                "at index ${i}: ${fileInfo}");
      }
      uris.add(uri);
    }
    var pendingWrites = <Future>[];
    for (int i = 0; i < uris.length; i++) {
      List<int> decodedFileContents = base64.decode(files[i][1]);
      pendingWrites.add(writeFile(uris[i], decodedFileContents));
    }
    await Future.wait(pendingWrites);
    return encodeSuccess(message);
  }

  Future<String> _listDevFSFiles(Message message) async {
    var listFiles = VMServiceEmbedderHooks.listFiles;
    if (listFiles == null) {
      return _encodeDevFSDisabledError(message);
    }
    var fsName = message.params['fsName'];
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
    var fileList = await listFiles(fs.uri);
    // Remove any url-encoding in the filenames.
    for (int i = 0; i < fileList.length; i++) {
      fileList[i]['name'] = Uri.decodeFull(fileList[i]['name']);
    }
    var result = {'type': 'FSFileList', 'files': fileList};
    return encodeResult(message, result);
  }
}
