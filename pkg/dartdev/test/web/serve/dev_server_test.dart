// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/web/project.dart';
import 'package:dartdev/src/web/serve/dev_server.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

/// Tests that the server answers on every address `localhost` stands for,
/// prints a URL a browser can open, and serves what the source maps list.
Future<void> main() async {
  final supportsIPv6 = await _supportsIPv6();
  late DevServer server;

  setUpAll(() async {
    server = await DevServer.start(
      await WebProject.find(await createWebApp()),
      port: 0,
    );
  });

  tearDownAll(() => server.close());

  test('url is http://localhost:<port> for localhost', () {
    expect(server.url, Uri.parse('http://localhost:${server.url.port}'));
    expect(server.isLoopback, isTrue);
  });

  // `localhost` would be wrong: the server listens on only one of the
  // addresses, and a browser may resolve `localhost` to the other one.
  for (final (hostname, expected) in [
    ('127.0.0.1', 'http://127.0.0.1'),
    ('::1', 'http://[::1]'),
  ]) {
    test('url is $expected:<port> for $hostname', () async {
      final server = await DevServer.start(
        await WebProject.find(await createWebApp()),
        hostname: hostname,
        port: 0,
      );
      addTearDown(server.close);
      expect(server.url, Uri.parse('$expected:${server.url.port}'));
      expect(server.isLoopback, isTrue);
      final client = HttpClient();
      addTearDown(client.close);
      final response = await (await client.getUrl(server.url)).close();
      expect(response.statusCode, HttpStatus.ok);
      await response.drain<void>();
    }, skip: hostname == '::1' && !supportsIPv6 ? 'No IPv6' : false);
  }

  // Other devices on the network can reach 0.0.0.0 (every address).
  test('is not loopback for 0.0.0.0', () async {
    final server = await DevServer.start(
      await WebProject.find(await createWebApp()),
      hostname: '0.0.0.0',
      port: 0,
    );
    addTearDown(server.close);
    expect(server.isLoopback, isFalse);
  });

  // Browsers may connect to either address for `localhost`, whichever it
  // resolves to first on the machine.
  for (final host in ['127.0.0.1', '[::1]']) {
    test('serves the app on http://$host', () async {
      final client = HttpClient();
      addTearDown(client.close);
      final request = await client.getUrl(
        Uri.parse('http://$host:${server.url.port}/'),
      );
      final response = await request.close();
      expect(response.statusCode, HttpStatus.ok);
      await response.drain<void>();
    }, skip: host == '[::1]' && !supportsIPv6 ? 'No IPv6' : false);
  }

  // A page on another site that resolves its own name to 127.0.0.1 (DNS
  // rebinding) sends its name in the Host header.
  test('rejects requests for other hosts', () async {
    final client = HttpClient();
    addTearDown(client.close);
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:${server.url.port}/'),
    );
    request.headers.host = 'attacker.example';
    final response = await request.close();
    expect(response.statusCode, HttpStatus.forbidden);
    await response.drain<void>();
  });

  // Browser devtools fetch these to show the Dart code behind the JS.
  test('serves every Dart source the source maps point to', () async {
    final client = HttpClient();
    addTearDown(client.close);
    Future<(int, String)> get(Uri url) async {
      final response = await (await client.getUrl(url)).close();
      return (response.statusCode, await utf8.decodeStream(response));
    }

    for (final map in [
      'web/main.dart.lib.js.map',
      'packages/hello_web/greeting.dart.lib.js.map',
      'dart_sdk.js.map',
    ]) {
      final mapUrl = server.url.resolve(map);
      final (_, body) = await get(mapUrl);
      final sources =
          (jsonDecode(body) as Map<String, Object?>)['sources']
              as List<Object?>;
      expect(sources, isNotEmpty, reason: map);
      for (final source in sources.cast<String>()) {
        final (status, contents) = await get(mapUrl.resolve(source));
        expect(status, HttpStatus.ok, reason: '$source (from $map)');
        expect(contents, isNotEmpty, reason: source);
      }
    }
  });
}

/// Whether this machine can listen on the IPv6 loopback address.
Future<bool> _supportsIPv6() async {
  try {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv6, 0);
    await socket.close();
    return true;
  } on SocketException {
    return false;
  }
}
