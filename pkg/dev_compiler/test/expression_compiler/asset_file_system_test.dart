// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpServer;

import 'package:browser_launcher/browser_launcher.dart';
import 'package:dev_compiler/src/kernel/asset_file_system.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:test/test.dart';

const _existingFile = 'existingFile';
const _nonExistingFile = 'nonExistingFile';

const _smallFileContents = 'Hello world!';
List<int> _smallFileBytes = utf8.encode(_smallFileContents);

String _largeFileContents() =>
    List.filled(10000, _smallFileContents).join('\n');
List<int> _largeFileBytes() => utf8.encode(_largeFileContents());

FutureOr<Response> handler(Request request) {
  final uri = request.requestedUri;
  final headers = {
    'content-length': '${utf8.encode(_smallFileContents).length}',
    ...request.headers,
  };

  if (request.method == 'HEAD') {
    // 'exists'
    return uri.pathSegments.last == _existingFile
        ? Response.ok(null, headers: headers)
        : Response.notFound(uri.toString());
  }
  if (request.method == 'GET') {
    // 'readAsBytes'
    return uri.pathSegments.last == _existingFile
        ? Response.ok(_smallFileContents, headers: headers)
        : Response.notFound(uri.toString());
  }
  return Response.internalServerError();
}

FutureOr<Response> noisyHandler(Request request) {
  final uri = request.requestedUri;
  final contents = _largeFileContents();
  final headers = {
    'content-length': '${utf8.encode(contents).length}',
    ...request.headers,
  };

  if (request.method == 'HEAD' || request.method == 'GET') {
    // 'exists' or 'readAsBytes'
    return uri.pathSegments.last == _existingFile
        ? Response.ok(contents, headers: headers)
        : Response.notFound(uri.toString());
  }
  return Response.internalServerError();
}

int _attempts = 0;
FutureOr<Response> unreliableHandler(Request request) {
  final uri = request.requestedUri;
  final headers = {
    'content-length': '${utf8.encode(_smallFileContents).length}',
    ...request.headers,
  };

  if ((_attempts++) % 5 == 0) return Response.internalServerError();

  if (request.method == 'HEAD') {
    // 'exists'
    return uri.pathSegments.last == _existingFile
        ? Response.ok(null, headers: headers)
        : Response.notFound(uri.toString());
  }
  if (request.method == 'GET') {
    // 'readAsBytes'
    return uri.pathSegments.last == _existingFile
        ? Response.ok(_smallFileContents, headers: headers)
        : Response.notFound(uri.toString());
  }
  return Response.internalServerError();
}

FutureOr<Response> alwaysFailingHandler(Request request) {
  return Response.internalServerError();
}

void main() async {
  late HttpServer server;
  late AssetFileSystem fileSystem;
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
      fileSystem.close();
    });

    test('can tell if file exists', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(await entity.exists(), true);
    });

    test('can tell if file does not exist', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_nonExistingFile));
      expect(await entity.exists(), false);
    });

    test('can read existing file using readAsBytes', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(await entity.readAsBytes(), _smallFileBytes);
    });

    test('can read and decode existing file using readAsBytes', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(utf8.decode(await entity.readAsBytes()), _smallFileContents);
    });

    test('can read existing file using readAsString', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(await entity.readAsString(), _smallFileContents);
    });

    test('cannot read non-existing file', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_nonExistingFile));
      await expectLater(
          entity.readAsBytes(), throwsA(isA<FileSystemException>()));
    });

    test('can read a lot of files concurrently', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      var futures = [
        for (var i = 0; i < 512; i++)
          _expectContents(entity, _smallFileContents),
      ];
      await Future.wait(futures);
    }, timeout: const Timeout.factor(2));
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
      fileSystem.close();
    });

    test('can tell if file exists', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(await entity.exists(), true);
    });

    test('can tell if file does not exist', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_nonExistingFile));
      expect(await entity.exists(), false);
    });

    test('can read existing file using readAsBytes', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(await entity.readAsBytes(), _largeFileBytes());
    });

    test('can read and decode existing file using readAsBytes', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(utf8.decode(await entity.readAsBytes()), _largeFileContents());
    });

    test('can read existing file using readAsString', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(await entity.readAsString(), _largeFileContents());
    });

    test('cannot read non-existing file', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_nonExistingFile));
      await expectLater(
          entity.readAsBytes(), throwsA(isA<FileSystemException>()));
    });

    test('readAsString is faster than decoding result of readAsBytes',
        () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));

      Future<int> elapsedReadAsString() async {
        var stopwatch = Stopwatch()..start();
        await expectLater(entity.readAsString(), isNotNull);
        return stopwatch.elapsedMilliseconds;
      }

      Future<int> elapsedReadAsBytesAndDecode() async {
        var stopwatch = Stopwatch()..start();
        await expectLater(utf8.decode(await entity.readAsBytes()), isNotNull);
        return stopwatch.elapsedMilliseconds;
      }

      await expectLater(await elapsedReadAsString(),
          lessThan(await elapsedReadAsBytesAndDecode()));
    });

    test('can read a lot of files concurrently', () async {
      var fileContents = _largeFileContents();
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      var futures = [
        for (var i = 0; i < 512; i++) _expectContents(entity, fileContents),
      ];
      await Future.wait(futures);
    }, timeout: const Timeout.factor(2));
  });

  group('AssetFileSystem with an unreliable server', () {
    setUpAll(() async {
      var hostname = 'localhost';
      var port = await findUnusedPort();

      server = await HttpMultiServer.bind(hostname, port);
      fileSystem =
          AssetFileSystem(StandardFileSystem.instance, hostname, '$port');

      serveRequests(server, unreliableHandler);
    });

    tearDownAll(() async {
      await expectLater(server.close(), completes);
      fileSystem.close();
    });

    test('can tell if file exists', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(await entity.exists(), true);
    });

    test('can tell if file does not exist', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_nonExistingFile));
      expect(await entity.exists(), false);
    });

    test('can read existing file using readAsBytes', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(await entity.readAsBytes(), _smallFileBytes);
    });

    test('can read and decode existing file using readAsBytes', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(utf8.decode(await entity.readAsBytes()), _smallFileContents);
    });

    test('can read existing file using readAsString', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(await entity.readAsString(), _smallFileContents);
    });

    test('cannot read non-existing file', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_nonExistingFile));
      await expectLater(
          entity.readAsBytes(), throwsA(isA<FileSystemException>()));
    });

    test('can read a lot of files concurrently', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      var futures = [
        for (var i = 0; i < 512; i++)
          _expectContents(entity, _smallFileContents),
      ];
      await Future.wait(futures);
    }, timeout: const Timeout.factor(2));
  });

  group('AssetFileSystem with failing server', () {
    setUpAll(() async {
      var hostname = 'localhost';
      var port = await findUnusedPort();

      server = await HttpMultiServer.bind(hostname, port);
      fileSystem =
          AssetFileSystem(StandardFileSystem.instance, hostname, '$port');

      serveRequests(server, alwaysFailingHandler);
    });

    tearDownAll(() async {
      await expectLater(server.close(), completes);
      fileSystem.close();
    });

    test('cannot tell if file exists', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      expect(await entity.exists(), false);
    });

    test('cannot tell if file does not exist', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_nonExistingFile));
      expect(await entity.exists(), false);
    });

    test('cannot read existing file using readAsBytes', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      await expectLater(
          entity.readAsBytes(), throwsA(isA<FileSystemException>()));
    });

    test('cannot read existing file using readAsString', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_existingFile));
      await expectLater(
          entity.readAsString(), throwsA(isA<FileSystemException>()));
    });

    test('cannot read non-existing file', () async {
      var entity = fileSystem.entityForUri(Uri.parse(_nonExistingFile));
      await expectLater(
          entity.readAsBytes(), throwsA(isA<FileSystemException>()));
    });
  });
}

// Read the response (and free the socket) as soon as we get it.
// That allows some connection to buffer and wait for free sockets
// when the limit if connections is reached.
Future<void> _expectContents(FileSystemEntity entity, String contents) async {
  var result = await entity.readAsString();
  expect(result, contents);
}
