// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('devtools', devtools, timeout: longTimeout);
}

void devtools() {
  late TestProject p;

  tearDown(() async => await p.dispose());

  test('--help', () async {
    p = project();
    var result = await p.run(['devtools', '--help']);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Open DevTools'));
    expect(result.stdout,
        contains('Usage: dart devtools [arguments] [service protocol uri]'));

    // Does not show verbose help.
    expect(result.stdout.contains('--try-ports'), isFalse);
  });

  test('--help --verbose', () async {
    p = project();
    var result = await p.run(['devtools', '--help', '--verbose']);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Open DevTools'));
    expect(
        result.stdout,
        contains(
            'Usage: dart [vm-options] devtools [arguments] [service protocol uri]'));

    // Shows verbose help.
    expect(result.stdout, contains('--try-ports'));
  });

  group('integration', () {
    Process? process;

    tearDown(() {
      process?.kill();
    });

    test('serves resources', () async {
      p = project();

      // start the devtools server
      process = await p.start(['devtools', '--no-launch-browser', '--machine']);
      process!.stderr.transform(utf8.decoder).listen(print);
      final Stream<String> inStream = process!.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter());

      final line = await inStream.first;
      final json = jsonDecode(line);

      // {"event":"server.started","method":"server.started","params":{
      //   "host":"127.0.0.1","port":9100,"pid":93508,"protocolVersion":"1.1.0"
      // }}
      expect(json['event'], 'server.started');
      expect(json['params'], isNotNull);

      final host = json['params']['host'];
      final port = json['params']['port'];
      expect(host, isA<String>());
      expect(port, isA<int>());

      // Connect to the port and confirm we can load a devtools resource.
      HttpClient client = HttpClient();
      final httpRequest = await client.get(host, port, 'index.html');
      final httpResponse = await httpRequest.close();

      final contents =
          (await httpResponse.transform(utf8.decoder).toList()).join();
      client.close();

      expect(contents, contains('DevTools'));

      // kill the process
      process!.kill();
      process = null;
    });
  });
}
