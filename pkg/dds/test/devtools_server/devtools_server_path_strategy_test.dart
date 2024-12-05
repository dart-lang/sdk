// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'utils/server_driver.dart';

late final DevToolsServerTestController testController;

void main() {
  testController = DevToolsServerTestController();
  final baseHrefRegex = RegExp('<base href="([^"]+)"');

  setUp(() async {
    await testController.setUp();
  });

  tearDown(() async {
    await testController.tearDown();
  });

  group('serves index.html', () {
    DevToolsServerDriver? server;
    late Uri devToolsUrl;
    final httpClient = HttpClient();

    setUpAll(() async {
      server = await DevToolsServerDriver.create();
      final startedEvent = (await server!.stdout.firstWhere(
        (map) => map!['event'] == 'server.started',
      ))!;
      final host = startedEvent['params']['host'];
      final port = startedEvent['params']['port'];
      devToolsUrl = Uri(scheme: 'http', host: host, port: port);
    });

    tearDownAll(() {
      httpClient.close(force: true);
      server?.kill();
    });

    test('correct content for /inspector', () async {
      final req = await httpClient.getUrl(devToolsUrl.resolve('/inspector'));
      final resp = await req.close();
      expect(resp.statusCode, 200);
      final bodyContent = await resp.transform(utf8.decoder).join();
      expect(bodyContent, contains('Dart DevTools'));
    }, timeout: const Timeout.factor(10));

    test('serves 404 for requests that are not pages', () async {
      // The index page is only served up for extension-less requests.
      final req =
          await httpClient.getUrl(devToolsUrl.resolve('/inspector.html'));
      final resp = await req.close();
      expect(resp.statusCode, 404);
      await resp.drain();
    }, timeout: const Timeout.factor(10));

    /// A set of test cases to verify base hrefs for.
    ///
    /// The key is a suffix to go after /devtools/ in the URI.
    /// The value is the expected base href (which should always resolve back to
    /// `/devtools/` or in the case of an extension, the base of the extension).
    final testBaseHrefs = {
      '': '.',
      'inspector': '.',
      // TODO(dantup): Is there a way we could verify extension URLs here?
      // 'devtools_extensions/foo/': '.',
      // 'devtools_extensions/foo/bar': '.',
      // 'devtools_extensions/foo/bar/': '..',
      // 'devtools_extensions/foo/bar/baz': '../..',
    };

    for (final MapEntry(key: suffix, value: expectedBaseHref)
        in testBaseHrefs.entries) {
      test('with correct base href for /$suffix', () async {
        final req = await httpClient.getUrl(devToolsUrl.resolve('/inspector'));
        final resp = await req.close();
        expect(resp.statusCode, 200);
        final bodyContent = await resp.transform(utf8.decoder).join();

        // Extract the base href so if the test failures, we get a simpler error
        // than just the entire content.
        final actualBaseHref = baseHrefRegex.firstMatch(bodyContent)!.group(1);
        expect(actualBaseHref, htmlEscape.convert(expectedBaseHref));
      }, timeout: const Timeout.factor(10));
    }
  }, timeout: const Timeout.factor(10));
}
