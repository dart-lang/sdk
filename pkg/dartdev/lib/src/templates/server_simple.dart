// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../templates.dart';
import 'common.dart' as common;

/// A generator for a server app built on `package:shelf`.
class ServerSimpleGenerator extends DefaultGenerator {
  ServerSimpleGenerator()
      : super('server-simple', 'Web Server',
            'A web server built using package:shelf.',
            categories: const ['dart', 'server']) {
    addFile('.gitignore', common.gitignore);
    addFile('analysis_options.yaml', common.analysisOptions);
    addFile('CHANGELOG.md', common.changelog);
    addFile('pubspec.yaml', _pubspec);
    addFile('README.md', _readme);
    setEntrypoint(
      addFile('bin/server.dart', _main),
    );
  }

  @override
  String getInstallInstructions() => '${super.getInstallInstructions()}\n'
      'run your app using `dart ${entrypoint.path}`.';
}

final String _pubspec = '''
name: __projectName__
description: A web server built using the shelf package.
version: 1.0.0
# homepage: https://www.example.com

environment:
  sdk: ">=2.12.0 <3.0.0"

dependencies:
  args: ^2.0.0
  shelf: ^1.1.0

dev_dependencies:
  pedantic: ^1.10.0
''';

final String _readme = '''
A web server built using [Shelf](https://pub.dev/packages/shelf).
''';

final String _main = r'''
import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = 'localhost';

void main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '8080';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(_echoRequest);

  var server = await io.serve(handler, _hostname, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

shelf.Response _echoRequest(shelf.Request request) =>
    shelf.Response.ok('Request for "${request.url}"');
''';
