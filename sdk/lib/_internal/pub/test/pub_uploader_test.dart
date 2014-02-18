// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_uploader_test;

import 'dart:convert';
import 'dart:io';

import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../lib/src/exit_codes.dart' as exit_codes;
import '../lib/src/io.dart';
import '../lib/src/utils.dart';
import 'descriptor.dart' as d;
import 'test_pub.dart';

final USAGE_STRING = '''
Manage uploaders for a package on pub.dartlang.org.

Usage: pub uploader [options] {add/remove} <email>
-h, --help       Print usage information for this command.
    --server     The package server on which the package is hosted.
                 (defaults to "https://pub.dartlang.org")

    --package    The package whose uploaders will be modified.
                 (defaults to the current package)
''';

ScheduledProcess startPubUploader(ScheduledServer server, List<String> args) {
  var tokenEndpoint = server.url.then((url) =>
      url.resolve('/token').toString());
  args = flatten(['uploader', '--server', tokenEndpoint, args]);
  return startPub(args: args, tokenEndpoint: tokenEndpoint);
}

main() {
  initConfig();
  group('displays usage', () {
    integration('when run with no arguments', () {
      schedulePub(args: ['uploader'],
          output: USAGE_STRING, exitCode: exit_codes.USAGE);
    });

    integration('when run with only a command', () {
      schedulePub(args: ['uploader', 'add'],
          output: USAGE_STRING, exitCode: exit_codes.USAGE);
    });

    integration('when run with an invalid command', () {
      schedulePub(args: ['uploader', 'foo', 'email'],
          output: USAGE_STRING, exitCode: exit_codes.USAGE);
    });
  });

  integration('adds an uploader', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPubUploader(server, ['--package', 'pkg', 'add', 'email']);

    server.handle('POST', '/api/packages/pkg/uploaders', (request) {
      expect(new ByteStream(request).toBytes().then((bodyBytes) {
        expect(new String.fromCharCodes(bodyBytes), equals('email=email'));

        request.response.headers.contentType =
            new ContentType("application", "json");
        request.response.write(JSON.encode({
          'success': {'message': 'Good job!'}
        }));
        request.response.close();
      }), completes);
    });

    pub.stdout.expect('Good job!');
    pub.shouldExit(exit_codes.SUCCESS);
  });

  integration('removes an uploader', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPubUploader(server, ['--package', 'pkg', 'remove', 'email']);

    server.handle('DELETE', '/api/packages/pkg/uploaders/email', (request) {
      request.response.headers.contentType =
          new ContentType("application", "json");
      request.response.write(JSON.encode({
        'success': {'message': 'Good job!'}
      }));
      request.response.close();
    });

    pub.stdout.expect('Good job!');
    pub.shouldExit(exit_codes.SUCCESS);
  });

  integration('defaults to the current package', () {
    d.validPackage.create();

    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPubUploader(server, ['add', 'email']);

    server.handle('POST', '/api/packages/test_pkg/uploaders', (request) {
      request.response.headers.contentType =
          new ContentType("application", "json");
      request.response.write(JSON.encode({
        'success': {'message': 'Good job!'}
      }));
      request.response.close();
    });

    pub.stdout.expect('Good job!');
    pub.shouldExit(exit_codes.SUCCESS);
  });

  integration('add provides an error', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPubUploader(server, ['--package', 'pkg', 'add', 'email']);

    server.handle('POST', '/api/packages/pkg/uploaders', (request) {
      request.response.statusCode = 400;
      request.response.headers.contentType =
          new ContentType("application", "json");
      request.response.write(JSON.encode({
        'error': {'message': 'Bad job!'}
      }));
      request.response.close();
    });

    pub.stderr.expect('Bad job!');
    pub.shouldExit(1);
  });

  integration('remove provides an error', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPubUploader(server,
        ['--package', 'pkg', 'remove', 'e/mail']);

    server.handle('DELETE', '/api/packages/pkg/uploaders/e%2Fmail', (request) {
      request.response.statusCode = 400;
      request.response.headers.contentType =
          new ContentType("application", "json");
      request.response.write(JSON.encode({
        'error': {'message': 'Bad job!'}
      }));
      request.response.close();
    });

    pub.stderr.expect('Bad job!');
    pub.shouldExit(1);
  });

  integration('add provides invalid JSON', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPubUploader(server, ['--package', 'pkg', 'add', 'email']);

    server.handle('POST', '/api/packages/pkg/uploaders', (request) {
      request.response.write("{not json");
      request.response.close();
    });

    pub.stderr.expect(emitsLines(
        'Invalid server response:\n'
        '{not json'));
    pub.shouldExit(1);
  });

  integration('remove provides invalid JSON', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPubUploader(server, ['--package', 'pkg', 'remove', 'email']);

    server.handle('DELETE', '/api/packages/pkg/uploaders/email', (request) {
      request.response.write("{not json");
      request.response.close();
    });

    pub.stderr.expect(emitsLines(
        'Invalid server response:\n'
        '{not json'));
    pub.shouldExit(1);
  });
}
