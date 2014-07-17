// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_uploader_test;

import 'dart:convert';

import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../lib/src/exit_codes.dart' as exit_codes;
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

Run "pub help" to see global options.
See http://dartlang.org/tools/pub/cmd/pub-uploader.html for detailed documentation.
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
      return request.readAsString().then((body) {
        expect(body, equals('email=email'));

        return new shelf.Response.ok(JSON.encode({
          'success': {'message': 'Good job!'}
        }), headers: {'content-type': 'application/json'});
      });
    });

    pub.stdout.expect('Good job!');
    pub.shouldExit(exit_codes.SUCCESS);
  });

  integration('removes an uploader', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPubUploader(server, ['--package', 'pkg', 'remove', 'email']);

    server.handle('DELETE', '/api/packages/pkg/uploaders/email', (request) {
      return new shelf.Response.ok(JSON.encode({
        'success': {'message': 'Good job!'}
      }), headers: {'content-type': 'application/json'});
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
      return new shelf.Response.ok(JSON.encode({
        'success': {'message': 'Good job!'}
      }), headers: {'content-type': 'application/json'});
    });

    pub.stdout.expect('Good job!');
    pub.shouldExit(exit_codes.SUCCESS);
  });

  integration('add provides an error', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPubUploader(server, ['--package', 'pkg', 'add', 'email']);

    server.handle('POST', '/api/packages/pkg/uploaders', (request) {
      return new shelf.Response(400,
          body: JSON.encode({'error': {'message': 'Bad job!'}}),
          headers: {'content-type': 'application/json'});
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
      return new shelf.Response(400,
          body: JSON.encode({'error': {'message': 'Bad job!'}}),
          headers: {'content-type': 'application/json'});
    });

    pub.stderr.expect('Bad job!');
    pub.shouldExit(1);
  });

  integration('add provides invalid JSON', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPubUploader(server, ['--package', 'pkg', 'add', 'email']);

    server.handle('POST', '/api/packages/pkg/uploaders',
        (request) => new shelf.Response.ok("{not json"));

    pub.stderr.expect(emitsLines(
        'Invalid server response:\n'
        '{not json'));
    pub.shouldExit(1);
  });

  integration('remove provides invalid JSON', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPubUploader(server, ['--package', 'pkg', 'remove', 'email']);

    server.handle('DELETE', '/api/packages/pkg/uploaders/email',
        (request) => new shelf.Response.ok("{not json"));

    pub.stderr.expect(emitsLines(
        'Invalid server response:\n'
        '{not json'));
    pub.shouldExit(1);
  });
}
