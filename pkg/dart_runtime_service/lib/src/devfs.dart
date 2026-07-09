// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:vm_service/vm_service.dart' hide Response;

import 'dart_runtime_service.dart';
import 'dart_runtime_service_rpcs.dart';
import 'rpc_exceptions.dart';

/// A [DevelopmentFileSystem] rooted at [rootUri], providing restricted file
/// system access to clients.
abstract base class DevelopmentFileSystem {
  DevelopmentFileSystem({required this.name, required this.rootUri});

  final String name;
  final Uri rootUri;

  static Never throwInvalidUriParameter({
    required String method,
    required Object? uri,
  }) => RpcException.invalidParams.throwExceptionWithDetails(
    details: "$method: invalid 'uri' parameter: $uri",
  );

  static Never throwMissingUriParameter({required String method}) =>
      RpcException.invalidParams.throwExceptionWithDetails(
        details: "$method: expects the 'uri' parameter",
      );

  /// Reads the contents of the file at [uri].
  ///
  /// If the file does not exist, a [RpcException.fileDoesNotExist] exception
  /// is thrown.
  Future<RpcResponse> readFile({required String uri});

  /// Writes [bytes] to [uri].
  Future<void> writeFile({required String uri, required List<int> bytes});

  /// Writes a stream of [bytes] to [uri].
  Future<void> writeStreamFile({
    required String uri,
    required Stream<List<int>> bytes,
  });

  /// Lists all files contained in the [DevelopmentFileSystem].
  ///
  /// Each file is reported with its size in bytes and last modified timestamp
  /// in milliseconds since epoch.
  Future<RpcResponse> listFiles();

  /// Resolves the [uri] against the [rootUri] of the [DevelopmentFileSystem].
  ///
  /// [uri] must be a valid file URI with an optional leading `/`. If the
  /// resolved URI is not within the file systems [rootUri], an
  /// [RpcException.invalidParams] exception is thrown.
  Uri resolve({required String method, required String uri}) {
    // The leading '/' is optional but must be removed before resolving the
    // URI, otherwise it will be treated as the file system root.
    if (uri.startsWith('/')) {
      uri = uri.substring(1);
    }
    final parsedUri = Uri.tryParse(uri);
    if (parsedUri == null) {
      throwInvalidUriParameter(method: method, uri: uri);
    }
    try {
      // Make sure that this pathUri can be converted to a file path.
      parsedUri.toFilePath();
      // ignore: avoid_catching_errors
    } on UnsupportedError {
      throwInvalidUriParameter(method: method, uri: uri);
    }

    final resolvedUri = rootUri.resolveUri(parsedUri);
    if (!resolvedUri.toString().startsWith(rootUri.toString())) {
      // Resolved uri must be within the filesystem's base uri.
      throwInvalidUriParameter(method: method, uri: uri);
    }
    return resolvedUri;
  }

  Map<String, String> toJson() => {
    'type': 'FileSystem',
    'name': name,
    'uri': rootUri.toString(),
  };
}

/// A collection of [DevelopmentFileSystem]s.
abstract base class DevelopmentFileSystemCollection {
  List<String> get fsNames;

  /// Destroys all [DevelopmentFileSystem]s in the collection.
  Future<void> cleanup();

  /// Creates a new [DevelopmentFileSystem] named [name].
  ///
  /// Throws a [RpcException.fileSystemAlreadyExists] if the file system has
  /// already been created.
  Future<DevelopmentFileSystem> createFileSystem({required String name});

  /// Destroys the [DevelopmentFileSystem] with name [name].
  ///
  /// Throws a [RpcException.fileSystemDoesNotExist] if the file system does
  /// not exist.
  Future<void> deleteFileSystem({required String name});

  /// Retrieves an existing [DevelopmentFileSystem] based on a JSON-RPC
  /// request.
  ///
  /// Throws a [RpcException.fileSystemDoesNotExist] if the file system does
  /// not exist.
  DevelopmentFileSystem getFileSystem({required String name});
}

/// A development file system used by service clients to upload compilation
/// artifacts and assets for use by the runtime.
class DevFS<DevFSBackend extends DevelopmentFileSystemCollection> {
  DevFS({required this._fileSystems});

  final DevFSBackend _fileSystems;
  final _logger = Logger('$DevFS');

  static const _kFsName = 'fsName';
  static const _kUri = 'uri';
  static const _kFiles = 'files';
  static const _kFileContents = 'fileContents';

  late final rpcs = UnmodifiableListView<ServiceRpcHandler>([
    ('_listDevFS', listDevFS),
    ('_createDevFS', createDevFS),
    ('_deleteDevFS', deleteDevFS),
    ('_readDevFSFile', readDevFSFile),
    ('_writeDevFSFile', writeDevFSFile),
    ('_writeDevFSFiles', writeDevFSFiles),
    ('_listDevFSFiles', listDevFSFiles),
  ]);

  // Destroy the development file systems.
  Future<void> cleanup() => _fileSystems.cleanup();

  /// Responsible for processing file system writes initiated via an HTTP PUT
  /// request.
  ///
  /// In order to write a file, the HTTP PUT request must include the following
  /// query parameters:
  ///   - `dev_fs_name`: the name of the [DevelopmentFileSystem] to write to.
  ///   - `dev_fs_uri_b64`: the base-64 encoded URI for the file to be written.
  ///
  /// The request body will be treated as the contents of the file and written
  /// to the provided URI rooted in the [DevelopmentFileSystem].
  Future<Response?> handlePutStreamRequest(Request request) async {
    if (request.method != 'PUT') {
      return null;
    }
    _logger.info('Handling DevFS PUT request: ${request.headers}');
    String? fsUri;

    const kDevFsName = 'dev_fs_name';
    const kDevFsUriBase64 = 'dev_fs_uri_b64';

    // Extract the fs name and fs path from the request headers.
    final fsName = request.headers[kDevFsName];
    if (fsName == null) {
      _logger.info('Invalid $kDevFsName. Returning.');
      // TODO(bkonyi): this is wrong
      return Response.internalServerError(body: 'Invalid $kDevFsName.');
    }
    if (request.headers[kDevFsUriBase64] case final String base64Uri) {
      fsUri = utf8.decode(base64.decode(base64Uri));
    }

    if (fsUri == null) {
      DevelopmentFileSystem.throwMissingUriParameter(method: '_writeDevFSFile');
    }

    _logger.info('Invoking handlePutStream.');

    final result = await _handlePutStream(
      fsName: fsName,
      uri: fsUri,
      bytes: request.read().cast<List<int>>().transform(gzip.decoder),
    );
    _logger.info('handlePutStream response: $result');

    return Response.ok(
      json.encode({'result': result}),
      headers: {
        // We closed the connection for bad origins earlier.
        'Access-Control-Allow-Origin': '*',
        'content-type': ContentType.json.mimeType,
      },
    );
  }

  Future<RpcResponse> _handlePutStream({
    required String fsName,
    required String uri,
    required Stream<List<int>> bytes,
  }) async {
    _logger.info('Handling PUT write to $uri in $fsName');
    final fs = _fileSystems.getFileSystem(name: fsName);
    await fs.writeStreamFile(uri: uri, bytes: bytes);
    return Success().toJson();
  }

  /// Lists the names of all active [DevelopmentFileSystem]s.
  RpcResponse listDevFS() =>
      // TODO(bkonyi): create package:vm_service type if we make this public.
      {'type': 'FileSystemList', 'fsNames': _fileSystems.fsNames};

  /// Creates a new [DevelopmentFileSystem] with a given `fsName`.
  ///
  /// If a [DevelopmentFileSystem] with `fsName` already exists, an error is
  /// returned.
  Future<RpcResponse> createDevFS(json_rpc.Parameters parameters) async {
    final fs = await _fileSystems.createFileSystem(
      name: parameters[_kFsName].asString,
    );
    return fs.toJson();
  }

  /// Deletes the [DevelopmentFileSystem] with name `fsName`.
  ///
  /// If a [DevelopmentFileSystem] with `fsName` does not exist, an error is
  /// returned.
  Future<RpcResponse> deleteDevFS(json_rpc.Parameters parameters) async {
    await _fileSystems.deleteFileSystem(name: parameters[_kFsName].asString);
    return Success().toJson();
  }

  /// Reads a file from `uri` within the [DevelopmentFileSystem] `fsName`.
  ///
  /// If a [DevelopmentFileSystem] with `fsName` does not exist, or `uri` is
  /// does not point to a valid file, an error is returned.
  Future<RpcResponse> readDevFSFile(json_rpc.Parameters parameters) async {
    final fs = _fileSystems.getFileSystem(name: parameters[_kFsName].asString);
    final uri = parameters[_kUri].asString;
    return await fs.readFile(uri: uri);
  }

  /// Writes `fileContents` to `uri` within the [DevelopmentFileSystem]
  /// `fsName`.
  ///
  /// If a [DevelopmentFileSystem] with `fsName` does not exist, an error is
  /// returned.
  Future<RpcResponse> writeDevFSFile(json_rpc.Parameters parameters) async {
    final fs = _fileSystems.getFileSystem(name: parameters[_kFsName].asString);
    final path = parameters[_kUri].asString;
    final fileContents = parameters[_kFileContents].asString;
    final decodedFileContents = base64.decode(fileContents);
    await fs.writeFile(uri: path, bytes: decodedFileContents);
    return Success().toJson();
  }

  /// Writes multiple `files` within the [DevelopmentFileSystem] `fsName`.
  ///
  /// Each entry in `files` is a list with two entries:
  ///   - The URI of the file to be written to.
  ///   - The contents of the file.
  ///
  /// If a [DevelopmentFileSystem] with `fsName` does not exist, an error is
  /// returned.
  Future<RpcResponse> writeDevFSFiles(json_rpc.Parameters parameters) async {
    final fs = _fileSystems.getFileSystem(name: parameters[_kFsName].asString);
    final files = parameters[_kFiles].asList.cast<Object?>();
    final processed = <(String, Uint8List)>[];

    Never throwInvalidFiles({required int index, required Object? fileInfo}) =>
        RpcException.invalidParams.throwExceptionWithDetails(
          details:
              "_writeDevFSFiles: invalid '$_kFiles' parameter at index $index: "
              '$fileInfo',
        );

    for (var i = 0; i < files.length; i++) {
      final fileInfo = files[i];
      if (fileInfo case [final String uriString, final String contents]) {
        try {
          fs.resolve(method: '_writeDevFSFiles', uri: uriString);
          processed.add((uriString, base64.decode(contents)));
        } catch (_) {
          throwInvalidFiles(index: i, fileInfo: fileInfo);
        }
      } else {
        throwInvalidFiles(index: i, fileInfo: fileInfo);
      }
    }
    final pendingWrites = <Future<void>>[];
    for (final (path, decodedContents) in processed) {
      pendingWrites.add(fs.writeFile(uri: path, bytes: decodedContents));
    }
    await Future.wait(pendingWrites);
    return Success().toJson();
  }

  /// Lists the set of files contained within the [DevelopmentFileSystem],
  /// `fsName`.
  ///
  /// If a [DevelopmentFileSystem] with `fsName` does not exist, an error is
  /// returned.
  Future<RpcResponse> listDevFSFiles(json_rpc.Parameters parameters) async {
    final fs = _fileSystems.getFileSystem(name: parameters[_kFsName].asString);
    return await fs.listFiles();
  }
}
