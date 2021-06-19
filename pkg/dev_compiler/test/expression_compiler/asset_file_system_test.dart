// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpServer;

import 'package:browser_launcher/browser_launcher.dart';
import 'package:dev_compiler/src/kernel/expression_compiler_worker.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:test/test.dart';

const _existingFile = 'http://localhost/existingFile';
const _nonExistingFile = 'http://localhost/nonExistingFile';

const _smallFileContents = 'Hello world!';

String _largeFileContents() =>
    List.filled(10000, _smallFileContents).join('/n');

FutureOr<Response> handler(Request request) {
  final uri = request.requestedUri.queryParameters['uri'];
  final headers = {
    'content-length': '${utf8.encode(_smallFileContents).length}',
    ...request.headers,
  };

  if (request.method == 'HEAD') {
    // 'exists'
    return uri == _existingFile
        ? Response.ok(null, headers: headers)
        : Response.notFound(uri);
  }
  if (request.method == 'GET') {
    // 'readAsBytes'
    return uri == _existingFile
        ? Response.ok(_smallFileContents, headers: headers)
        : Response.notFound(uri);
  }
  return Response.internalServerError();
}

FutureOr<Response> noisyHandler(Request request) {
  final uri = request.requestedUri.queryParameters['uri'];
  final contents = _largeFileContents();
  final headers = {
    'content-length': '${utf8.encode(contents).length}',
    ...request.headers,
  };

  if (request.method == 'HEAD' || request.method == 'GET') {
    // 'exists' or 'readAsBytes'
    return uri == _existingFile
        ? Response.ok(contents, headers: headers)
        : Response.notFound(uri);
  }
  return Response.internalServerError();
}

void main() async {
  HttpServer server;
  AssetFileSystem fileSystem;
  group('AssetFileSystem with a server', () {
    setUpAll(() async {
      var hostname = 'localhost';
      var port = await findUnusedPort();

      server = await HttpMultiServer.bind(hostname, port);
      fileSystem =
          AssetFileSystem(StandardFileSystem.instance, hostname, '$port');

      serveRequests(server, handler);
    });

    tearDownAll(() async {
      await expectLater(server.close(), completes);
    });

    test('can tell if file exists', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(await entity.exists(), true);
    });

    test('can tell if file does not exist', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_nonExistingFile));
      expect(await entity.exists(), false);
    });

    test('can read existing file', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(utf8.decode(await entity.readAsBytes()), _smallFileContents);
    });

    test('cannot read non-existing file', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_nonExistingFile));
      await expectLater(
          entity.readAsBytes(), throwsA(isA<FileSystemException>()));
    });
  });

  group('AssetFileSystem with a noisy server', () {
    setUpAll(() async {
      var hostname = 'localhost';
      var port = await findUnusedPort();

      server = await HttpMultiServer.bind(hostname, port);
      fileSystem =
          AssetFileSystem(StandardFileSystem.instance, hostname, '$port');

      serveRequests(server, noisyHandler);
    });

    tearDownAll(() async {
      await expectLater(server.close(), completes);
    });

    test('can tell if file exists', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(await entity.exists(), true);
    });

    test('can tell if file does not exist', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_nonExistingFile));
      expect(await entity.exists(), false);
    });

    test('can read existing file', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(utf8.decode(await entity.readAsBytes()), _largeFileContents());
    });

    test('cannot read non-existing file', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_nonExistingFile));
      await expectLater(
          entity.readAsBytes(), throwsA(isA<FileSystemException>()));
    });
  });
}
