// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../utils.dart' as utils;

void main() {
  group(
    'language-server',
    defineLanguageServerTests,
    timeout: utils.longTimeout,
    onPlatform: {
      'windows': Skip('https://github.com/dart-lang/sdk/issues/44679'),
    },
  );
}

void defineLanguageServerTests() {
  late utils.TestProject project;
  Process? process;

  tearDown(() async => await project.dispose());

  Future runWithLsp(List<String> args) async {
    project = utils.project();

    process = await project.start(args);

    final Stream<String> inStream =
        process!.stdout.transform<String>(utf8.decoder);

    // Send an LSP init.
    final String message = jsonEncode({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {
        'processId': pid,
        'clientInfo': {'name': 'dart-cli-tester'},
        'capabilities': {},
        'rootUri': project.dir.uri.toString(),
      },
    });

    process!.stdin.write('Content-Length: ${message.length}\r\n');
    process!.stdin.write('\r\n');
    process!.stdin.write(message);

    List<String> responses = await inStream.take(2).toList();
    expect(responses, hasLength(2));

    expect(responses[0], startsWith('Content-Length: '));

    final json = jsonDecode(responses[1]);
    expect(json['id'], 1);
    expect(json['result'], isNotNull);
    final result = json['result'];
    expect(result['capabilities'], isNotNull);
    expect(result['serverInfo'], isNotNull);
    final serverInfo = result['serverInfo'];
    expect(serverInfo['name'], isNotEmpty);

    process!.kill();
    process = null;
  }

  test('protocol default', () async {
    return runWithLsp(['language-server']);
  });

  test('protocol lsp', () async {
    return runWithLsp(['language-server', '--protocol=lsp']);
  });

  test('protocol analyzer', () async {
    project = utils.project();

    process = await project.start(['language-server', '--protocol=analyzer']);

    final Stream<String> inStream = process!.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter());

    final line = await inStream.first;
    final json = jsonDecode(line);

    expect(json['event'], 'server.connected');
    expect(json['params'], isNotNull);
    final params = json['params'];
    expect(params['version'], isNotEmpty);
    expect(params['pid'], isNot(0));

    process!.kill();
    process = null;
  });
}
