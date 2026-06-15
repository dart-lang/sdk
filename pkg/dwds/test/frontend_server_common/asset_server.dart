// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Note: this is a copy from flutter tools, updated to work with dwds tests

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dwds/asset_reader.dart';
import 'package:dwds/config.dart';
import 'package:dwds_test_common/test_sdk_layout.dart';
import 'package:file/file.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart' as mime;
import 'package:shelf/shelf.dart' as shelf;

class TestAssetServer implements AssetReader {
  late final String _basePath;
  final String index;

  final _logger = Logger('TestAssetServer');

  // Fallback to "application/octet-stream" on null which
  // makes no claims as to the structure of the data.
  static const String _defaultMimeType = 'application/octet-stream';
  final Uri _projectDirectory;
  final FileSystem _fileSystem;
  final HttpServer _httpServer;
  final Map<String, Uint8List> _files = {};
  final Map<String, Uint8List> _sourceMaps = {};
  final Map<String, Uint8List> _metadata = {};
  late String _mergedMetadata;
  final PackageUriMapper _packageUriMapper;
  final InternetAddress internetAddress;
  final TestSdkLayout _sdkLayout;

  TestAssetServer(
    this.index,
    this._httpServer,
    this._packageUriMapper,
    this.internetAddress,
    this._projectDirectory,
    this._fileSystem,
    this._sdkLayout,
  ) {
    _basePath = _parseBasePathFromIndexHtml(index);
  }

  @override
  String get basePath => _basePath;

  bool hasFile(String path) => _files.containsKey(path);
  Uint8List getFile(String path) => _files[path]!;

  bool hasSourceMap(String path) => _sourceMaps.containsKey(path);
  Uint8List getSourceMap(String path) => _sourceMaps[path]!;

  bool hasMetadata(String path) => _metadata.containsKey(path);
  Uint8List getMetadata(String path) => _metadata[path]!;

  /// Start the web asset server on a [hostname] and [port].
  ///
  /// Unhandled exceptions will throw a exception with the error and stack
  /// trace.
  static Future<TestAssetServer> start(
    String sdkDirectory,
    Uri projectDirectory,
    FileSystem fileSystem,
    String index,
    String hostname,
    int port,
    UrlEncoder? urlTunneler,
    PackageUriMapper packageUriMapper,
  ) async {
    final address = (await InternetAddress.lookup(hostname)).first;
    final httpServer = await HttpServer.bind(address, port);
    final sdkLayout = TestSdkLayout.createDefault(sdkDirectory);
    final server = TestAssetServer(
      index,
      httpServer,
      packageUriMapper,
      address,
      projectDirectory,
      fileSystem,
      sdkLayout,
    );
    return server;
  }

  // handle requests for JavaScript source, dart sources maps, or asset files.
  Future<shelf.Response> handleRequest(shelf.Request request) async {
    if (request.method != 'GET') {
      // Assets are served via GET only.
      return shelf.Response.notFound('');
    }
    final requestPath = _stripBasePath(request.url.path, basePath);
    if (requestPath == null) {
      return shelf.Response.notFound('');
    }

    final headers = <String, String>{};

    if (request.url.path.endsWith('.html')) {
      final indexFile = _fileSystem.file(_projectDirectory.resolve(index));
      if (indexFile.existsSync()) {
        headers[HttpHeaders.contentTypeHeader] = 'text/html';
        headers[HttpHeaders.contentLengthHeader] = indexFile
            .lengthSync()
            .toString();
        return shelf.Response.ok(indexFile.openRead(), headers: headers);
      }
      return shelf.Response.notFound('');
    }

    // If this is a JavaScript file, it must be in the in-memory cache.
    // Attempt to look up the file by URI.
    if (hasFile(requestPath)) {
      final List<int> bytes = getFile(requestPath);
      headers[HttpHeaders.contentLengthHeader] = bytes.length.toString();
      headers[HttpHeaders.contentTypeHeader] = 'application/javascript';
      return shelf.Response.ok(bytes, headers: headers);
    }
    // If this is a sourcemap file, then it might be in the in-memory cache.
    // Attempt to lookup the file by URI.
    if (hasSourceMap(requestPath)) {
      final List<int> bytes = getSourceMap(requestPath);
      headers[HttpHeaders.contentLengthHeader] = bytes.length.toString();
      headers[HttpHeaders.contentTypeHeader] = 'application/json';
      return shelf.Response.ok(bytes, headers: headers);
    }
    // If this is a metadata file, then it might be in the in-memory cache.
    // Attempt to lookup the file by URI.
    if (hasMetadata(requestPath)) {
      final List<int> bytes = getMetadata(requestPath);
      headers[HttpHeaders.contentLengthHeader] = bytes.length.toString();
      headers[HttpHeaders.contentTypeHeader] = 'application/json';
      return shelf.Response.ok(bytes, headers: headers);
    }

    final file = _resolveDartFile(requestPath);
    if (!file.existsSync()) {
      return shelf.Response.notFound('');
    }

    final length = file.lengthSync();
    // Attempt to determine the file's mime type. if this is not provided some
    // browsers will refuse to render images/show video et cetera. If the tool
    // cannot determine a mime type, fall back to application/octet-stream.
    String? mimeType;
    if (length >= 12) {
      mimeType = mime.lookupMimeType(
        file.path,
        headerBytes: await file.openRead(0, 12).first,
      );
    }
    mimeType ??= _defaultMimeType;
    headers[HttpHeaders.contentLengthHeader] = length.toString();
    headers[HttpHeaders.contentTypeHeader] = mimeType;
    return shelf.Response.ok(file.openRead(), headers: headers);
  }

  /// Tear down the http server running.
  @override
  Future<void> close() {
    return _httpServer.close();
  }

  /// Write a single file into the in-memory cache.
  void writeFile(String filePath, String contents) {
    _files[filePath] = Uint8List.fromList(utf8.encode(contents));
  }

  /// Update the in-memory asset server with the provided source and manifest
  /// files.
  ///
  /// Returns a list of updated modules.
  List<String> write(
    File codeFile,
    File manifestFile,
    File sourcemapFile,
    File metadataFile,
  ) {
    final modules = <String>[];
    final codeBytes = codeFile.readAsBytesSync();
    final sourcemapBytes = sourcemapFile.readAsBytesSync();
    final metadataBytes = metadataFile.readAsBytesSync();
    final manifest = _castStringKeyedMap(
      json.decode(manifestFile.readAsStringSync()),
    );
    for (final filePath in manifest.keys) {
      final offsets = _castStringKeyedMap(manifest[filePath]);
      final codeOffsets = (offsets['code'] as List<dynamic>).cast<int>();
      final sourcemapOffsets = (offsets['sourcemap'] as List<dynamic>)
          .cast<int>();
      final metadataOffsets = (offsets['metadata'] as List<dynamic>)
          .cast<int>();
      if (codeOffsets.length != 2 ||
          sourcemapOffsets.length != 2 ||
          metadataOffsets.length != 2) {
        _logger.severe('Invalid manifest byte offsets: $offsets');
        continue;
      }

      final codeStart = codeOffsets[0];
      final codeEnd = codeOffsets[1];
      if (codeStart < 0 || codeEnd > codeBytes.lengthInBytes) {
        _logger.severe('Invalid byte index: [$codeStart, $codeEnd]');
        continue;
      }
      final byteView = Uint8List.view(
        codeBytes.buffer,
        codeStart,
        codeEnd - codeStart,
      );

      final fileName = filePath.startsWith('/')
          ? filePath.substring(1)
          : filePath;
      _files[fileName] = byteView;

      final sourcemapStart = sourcemapOffsets[0];
      final sourcemapEnd = sourcemapOffsets[1];
      if (sourcemapStart < 0 || sourcemapEnd > sourcemapBytes.lengthInBytes) {
        _logger.severe('Invalid byte index: [$sourcemapStart, $sourcemapEnd]');
        continue;
      }
      final sourcemapView = Uint8List.view(
        sourcemapBytes.buffer,
        sourcemapStart,
        sourcemapEnd - sourcemapStart,
      );
      _sourceMaps['$fileName.map'] = sourcemapView;

      final metadataStart = metadataOffsets[0];
      final metadataEnd = metadataOffsets[1];
      if (metadataStart < 0 || metadataEnd > metadataBytes.lengthInBytes) {
        _logger.severe('Invalid byte index: [$metadataStart, $metadataEnd]');
        continue;
      }
      final metadataView = Uint8List.view(
        metadataBytes.buffer,
        metadataStart,
        metadataEnd - metadataStart,
      );
      _metadata['$fileName.metadata'] = metadataView;

      modules.add(fileName);
    }

    _mergedMetadata = _metadata.values
        .map((Uint8List encoded) => utf8.decode(encoded))
        .join('\n');

    return modules;
  }

  // Attempt to resolve `path` to a dart file.
  File _resolveDartFile(String path) {
    // If this is a dart file, it must be on the local file system and is
    // likely coming from a source map request. The tool doesn't currently
    // consider the case of Dart files as assets.
    final dartFile = _fileSystem.file(_projectDirectory.resolve(path));
    if (dartFile.existsSync()) {
      return dartFile;
    }

    final segments = path.split('/');

    // The file might have been a package file which is signaled by a
    // `/packages/<package>/<path>` request.
    if (segments.first == 'packages') {
      var resolved = _packageUriMapper.serverPathToResolvedUri(path);
      if (resolved != null) {
        resolved = _projectDirectory.resolveUri(resolved);
      }
      final packageFile = _fileSystem.file(resolved);
      if (packageFile.existsSync()) {
        return packageFile;
      }
      _logger.severe('Package file not found: $path ($packageFile)');
    }

    // Otherwise it must be a Dart SDK source.
    final dartSdkParent = _fileSystem.directory(_sdkLayout.sdkDirectory).parent;
    final dartSdkFile = _fileSystem.file(
      _fileSystem.path.joinAll(<String>[dartSdkParent.path, ...segments]),
    );
    return dartSdkFile;
  }

  @override
  Future<String?> dartSourceContents(String serverPath) async {
    final stripped = _stripBasePath(serverPath, basePath);
    if (stripped != null) {
      final result = _resolveDartFile(stripped);
      if (result.existsSync()) {
        return result.readAsString();
      }
    }
    _logger.severe('Source not found: $serverPath');
    return null;
  }

  @override
  Future<String?> sourceMapContents(String serverPath) async {
    final stripped = _stripBasePath(serverPath, basePath);
    if (stripped != null) {
      if (hasSourceMap(stripped)) {
        return utf8.decode(getSourceMap(stripped));
      }
    }
    _logger.severe('Source map not found: $serverPath');
    return null;
  }

  @override
  Future<String?> metadataContents(String serverPath) async {
    final stripped = _stripBasePath(serverPath, basePath);
    if (stripped != null) {
      if (stripped.endsWith('.ddc_merged_metadata')) {
        return _mergedMetadata;
      }
      if (hasMetadata(stripped)) {
        return utf8.decode(getMetadata(stripped));
      }
    }
    _logger.severe('Metadata not found: $serverPath');
    return null;
  }

  String _parseBasePathFromIndexHtml(String index) {
    final file = _fileSystem.file(_projectDirectory.resolve(index));
    if (!file.existsSync()) {
      throw StateError('Index file $index is not found');
    }
    final contents = file.readAsStringSync();
    final matches = RegExp(r'<base href="/([^>]*)/">').allMatches(contents);
    if (matches.isEmpty) return '';
    return matches.first.group(1) ?? '';
  }

  String? _stripBasePath(String path, String basePath) {
    path = stripLeadingSlashes(path);
    if (path.startsWith(basePath)) {
      path = path.substring(basePath.length);
    } else {
      // The given path isn't under base path, return null to indicate that.
      _logger.severe('Path is not under $basePath: $path');
      return null;
    }
    return stripLeadingSlashes(path);
  }
}

/// Given a data structure which is a Map of String to dynamic values, return
/// the same structure (`Map<String, dynamic>`) with the correct runtime types.
Map<String, dynamic> _castStringKeyedMap(dynamic untyped) {
  final map = untyped as Map<dynamic, dynamic>;
  return map.cast<String, dynamic>();
}
