// Copyright 2024 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dds/devtools_server.dart';
import 'package:test/test.dart';

import 'utils/server_driver.dart';

void main() {
  group('Dart Tooling Daemon connection', () {
    test('does not start DTD when a DTD uri is passed as an argument',
        () async {
      final server = await DevToolsServerDriver.create(
        additionalArgs: ['--${DevToolsServer.argDtdUri}=some_uri'],
      );
      try {
        final dtdStartedEvent = await server.stdout
            .firstWhere(
              (map) => map!['event'] == 'server.dtdStarted',
              orElse: () => null,
            )
            .timeout(
              const Duration(seconds: 3),
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
  });
}
