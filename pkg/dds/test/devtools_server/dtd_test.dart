// Copyright 2024 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dds/devtools_server.dart';
import 'package:test/test.dart';

import 'utils/server_driver.dart';

void main() {
  const dtdUriSwitch = '--${DevToolsServer.argDtdUri}';
  const dtdExposedUriSwitch = '--${DevToolsServer.argDtdExposedUri}';

  group('Dart Tooling Daemon connection', () {
    test('does not start DTD when a DTD uri is passed as an argument',
        () async {
      final server = await DevToolsServerDriver.create(
        additionalArgs: ['$dtdUriSwitch=ws://localhost:123/'],
      );
      try {
        // Ensure the event does not arrive within some reasonable amount of
        // time.
        final dtdStartedEvent = await server.stdout
            .firstWhere(
              (map) => map!['event'] == 'server.dtdStarted',
              orElse: () => null,
            )
            .timeout(
              Duration(seconds: 3),
              onTimeout: () => null,
            );
        expect(dtdStartedEvent, isNull);
      } finally {
        server.kill();
      }
    });

    test('starts DTD when no DTD uri is passed as an argument', () async {
      final server = await DevToolsServerDriver.create();
      try {
        final dtdStartedEvent = await server.stdout.firstWhere(
          (map) => map!['event'] == 'server.dtdStarted',
          orElse: () => null,
        );
        expect(dtdStartedEvent, isNotNull);
      } finally {
        server.kill();
      }
    });

    test('rejects invalid URIs for --dtd-uri', () async {
      final server = await DevToolsServerDriver.create(
        additionalArgs: ['$dtdUriSwitch=some_uri'],
      );
      try {
        final firstLine = await server.stdoutRaw.first;
        expect(firstLine, '$dtdUriSwitch must be a valid URI');
      } finally {
        server.kill();
      }
    });

    test('rejects invalid URIs for --dtd-exposed-uri', () async {
      final server = await DevToolsServerDriver.create(
        additionalArgs: [
          '$dtdUriSwitch=ws://localhost:123/',
          '$dtdExposedUriSwitch=some_uri'
        ],
      );
      try {
        final firstLine = await server.stdoutRaw.first;
        expect(firstLine, '$dtdExposedUriSwitch must be a valid URI');
      } finally {
        server.kill();
      }
    });

    test('rejects --dtd-exposed-uri without --dtd-uri', () async {
      final server = await DevToolsServerDriver.create(
        additionalArgs: ['$dtdExposedUriSwitch=some_uri'],
      );
      try {
        final firstLine = await server.stdoutRaw.first;
        expect(firstLine,
            '$dtdExposedUriSwitch can only be supplied with $dtdUriSwitch');
      } finally {
        server.kill();
      }
    });
  });
}
