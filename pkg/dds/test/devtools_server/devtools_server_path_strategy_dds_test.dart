// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils/server_driver.dart';

late final DevToolsServerTestController testController;

void main() {
  const testScriptContents =
      'Future<void> main() => Future.delayed(const Duration(minutes: 10));';
  final tempDir = Directory.systemTemp.createTempSync('devtools_server.');
  final devToolsBannerRegex =
      RegExp(r'DevTools[\w\s]+at: (https?:.*\/devtools/)');
  final baseHrefRegex = RegExp('<base href="([^"]+)"');

  group('serves index.html', () {
    Process? process;
    late Uri devToolsUrl;
    final httpClient = HttpClient();

    setUpAll(() async {
      final testFile = File(path.join(tempDir.path, 'foo.dart'));
      testFile.writeAsStringSync(testScriptContents);

      final proc = process = await Process.start(
          Platform.resolvedExecutable, ['--observe=0', testFile.path]);

      final completer = Completer<String>();
      proc.stderr
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .listen(print);
      proc.stdout.transform(utf8.decoder).transform(LineSplitter()).listen(
        (String line) {
          final match = devToolsBannerRegex.firstMatch(line);
          if (match != null) {
            completer.complete(match.group(1)!);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError(
                'Process ended without emitting DevTools banner');
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
      );
      devToolsUrl = Uri.parse(await completer.future);
    });

    tearDownAll(() {
      httpClient.close(force: true);
      process?.kill();
    });

    test('correct content for /token/devtools/', () async {
      final uri = devToolsUrl;
      final req = await httpClient.getUrl(uri);
      final resp = await req.close();
      expect(resp.statusCode, 200);
      final bodyContent = await resp.transform(utf8.decoder).join();
      expect(bodyContent, contains('Dart DevTools'));
    }, timeout: const Timeout.factor(10));

    /// A set of test cases to verify base hrefs for.
    ///
    /// The key is a suffix to go after /devtools/ in the URI.
    /// The value is the expected base href (which should always resolve back to
    /// `/devtools/` or in the case of an extension, the base of the extension).
    final testBaseHrefs = {
      '': '.',
      'inspector': '.',
      // We can't test devtools_extensions here without having one set up, but
      // their paths are also tested in `base_href_test.dart`.
    };

    for (final MapEntry(key: suffix, value: expectedBaseHref)
        in testBaseHrefs.entries) {
      test('with correct base href for /token/devtools/$suffix', () async {
        final uri = Uri.parse('$devToolsUrl$suffix');
        final req = await httpClient.getUrl(uri);
        final resp = await req.close();
        expect(resp.statusCode, 200);
        final bodyContent = await resp.transform(utf8.decoder).join();
        expect(bodyContent, contains('<base href="'));

        // Extract the base href so if the test failures, we get a simpler error
        // than just the entire content.
        final actualBaseHref = baseHrefRegex.firstMatch(bodyContent)!.group(1);
        expect(actualBaseHref, htmlEscape.convert(expectedBaseHref));
      }, timeout: const Timeout.factor(10));
    }
  }, timeout: const Timeout.factor(10));
}
