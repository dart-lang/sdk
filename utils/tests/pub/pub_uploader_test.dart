// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_uploader_test;

import 'dart:io';
import 'dart:json' as json;

import 'test_pub.dart';
import '../../../pkg/unittest/lib/unittest.dart';
import '../../pub/utils.dart';
import '../../pub/io.dart';

final USAGE_STRING = '''
    Manage uploaders for a package on pub.dartlang.org.

    Usage: pub uploader [options] {add/remove} <email>
    --server     The package server on which the package is hosted
                 (defaults to "https://pub.dartlang.org")

    --package    The package whose uploaders will be modified
                 (defaults to the current package)
    ''';

ScheduledProcess startPubUploader(ScheduledServer server, List<String> args) {
  var tokenEndpoint = server.url.then((url) =>
      url.resolve('/token').toString());
  args = flatten(['uploader', '--server', tokenEndpoint, args]);
  return startPub(args: args, tokenEndpoint: tokenEndpoint);
}

main() {
  group('displays usage', () {
    integration('when run with no arguments', () {
      schedulePub(args: ['uploader'],
          output: USAGE_STRING, exitCode: 64);
    });

    integration('when run with only a command', () {
      schedulePub(args: ['uploader', 'add'],
          output: USAGE_STRING, exitCode: 64);
    });

    integration('when run with an invalid command', () {
      schedulePub(args: ['uploader', 'foo', 'email'],
          output: USAGE_STRING, exitCode: 64);
    });
  });

  integration('adds an uploader', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubUploader(server, ['--package', 'pkg', 'add', 'email']);

    server.handle('POST', '/packages/pkg/uploaders.json', (request, response) {
      expect(consumeInputStream(request.inputStream).then((bodyBytes) {
        expect(new String.fromCharCodes(bodyBytes), equals('email=email'));

        response.headers.contentType = new ContentType("application", "json");
        response.outputStream.writeString(json.stringify({
          'success': {'message': 'Good job!'}
        }));
        response.outputStream.close();
      }), completes);
    });

    expectLater(pub.nextLine(), equals('Good job!'));
    pub.shouldExit(0);
  });

  integration('removes an uploader', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubUploader(server, ['--package', 'pkg', 'remove', 'email']);

    server.handle('DELETE', '/packages/pkg/uploaders/email.json',
        (request, response) {
      response.headers.contentType = new ContentType("application", "json");
      response.outputStream.writeString(json.stringify({
        'success': {'message': 'Good job!'}
      }));
      response.outputStream.close();
    });

    expectLater(pub.nextLine(), equals('Good job!'));
    pub.shouldExit(0);
  });

  integration('defaults to the current package', () {
    normalPackage.scheduleCreate();

    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubUploader(server, ['add', 'email']);

    server.handle('POST', '/packages/test_pkg/uploaders.json',
        (request, response) {
      response.headers.contentType = new ContentType("application", "json");
      response.outputStream.writeString(json.stringify({
        'success': {'message': 'Good job!'}
      }));
      response.outputStream.close();
    });

    expectLater(pub.nextLine(), equals('Good job!'));
    pub.shouldExit(0);
  });

  integration('add provides an error', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubUploader(server, ['--package', 'pkg', 'add', 'email']);

    server.handle('POST', '/packages/pkg/uploaders.json', (request, response) {
      response.statusCode = 400;
      response.headers.contentType = new ContentType("application", "json");
      response.outputStream.writeString(json.stringify({
        'error': {'message': 'Bad job!'}
      }));
      response.outputStream.close();
    });

    expectLater(pub.nextErrLine(), equals('Bad job!'));
    pub.shouldExit(1);
  });

  integration('remove provides an error', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubUploader(server,
        ['--package', 'pkg', 'remove', 'e/mail']);

    server.handle('DELETE', '/packages/pkg/uploaders/e%2Fmail.json',
        (request, response) {
      response.statusCode = 400;
      response.headers.contentType = new ContentType("application", "json");
      response.outputStream.writeString(json.stringify({
        'error': {'message': 'Bad job!'}
      }));
      response.outputStream.close();
    });

    expectLater(pub.nextErrLine(), equals('Bad job!'));
    pub.shouldExit(1);
  });

  integration('add provides invalid JSON', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubUploader(server, ['--package', 'pkg', 'add', 'email']);

    server.handle('POST', '/packages/pkg/uploaders.json', (request, response) {
      response.outputStream.writeString("{not json");
      response.outputStream.close();
    });

    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals('{not json'));
    pub.shouldExit(1);
  });

  integration('remove provides invalid JSON', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubUploader(server, ['--package', 'pkg', 'remove', 'email']);

    server.handle('DELETE', '/packages/pkg/uploaders/email.json',
        (request, response) {
      response.outputStream.writeString("{not json");
      response.outputStream.close();
    });

    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals('{not json'));
    pub.shouldExit(1);
  });
}
